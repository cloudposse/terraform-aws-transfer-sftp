locals {
  enabled                   = module.this.enabled
  kms_enabled               = local.enabled && var.kms_key_arn != null
  # If enabling a scope down policy, the session policy is assumed to reference the user home folders
  # in its policy. Hence we only need a single role for transfer service. The role arn can be referenced
  # in the S3 bucket policy.
  # See https://docs.aws.amazon.com/transfer/latest/userguide/users-policies.html#users-policies-session
  multi_role_policy_enabled = local.enabled && !var.scope_down_policy_enabled
  scope_down_policy_enabled = local.enabled && var.scope_down_policy_enabled

  is_vpc                 = var.vpc_id != null
  security_group_enabled = module.this.enabled && var.security_group_enabled
  user_names             = keys(var.sftp_users)
  user_names_map         = { for idx, user in local.user_names : idx => user }
}

data "aws_s3_bucket" "landing" {
  count = local.enabled ? 1 : 0

  bucket = var.s3_bucket_name
}

resource "aws_transfer_server" "default" {
  count = local.enabled ? 1 : 0

  identity_provider_type = "SERVICE_MANAGED"
  protocols              = ["SFTP"]
  domain                 = var.domain
  endpoint_type          = local.is_vpc ? "VPC" : "PUBLIC"
  force_destroy          = var.force_destroy
  security_policy_name   = var.security_policy_name
  logging_role           = join("", aws_iam_role.logging[*].arn)

  dynamic "endpoint_details" {
    for_each = local.is_vpc ? [1] : []

    content {
      subnet_ids             = var.subnet_ids
      security_group_ids     = local.security_group_enabled ? module.security_group.*.id : var.vpc_security_group_ids
      vpc_id                 = var.vpc_id
      address_allocation_ids = var.eip_enabled ? aws_eip.sftp.*.id : var.address_allocation_ids
    }
  }

  tags = module.this.tags
}

resource "aws_transfer_user" "default" {
  for_each = local.enabled ? var.sftp_users : {}
  server_id = join("", aws_transfer_server.default[*].id)
  role      = local.scope_down_policy_enabled ? join("", aws_iam_role.transfer_service_policy_default[*].arn) : aws_iam_role.s3_access_for_sftp_users[index(local.user_names, each.value.user_name)].arn

  user_name = each.value.user_name

  home_directory_type = var.restricted_home ? "LOGICAL" : "PATH"

  policy    = local.scope_down_policy_enabled ? data.aws_iam_policy_document.session_kms_access_for_sftp_users[0].json : null

  home_directory = var.restricted_home ? "" : "/${var.s3_bucket_name}/${each.value.user_name}"

  dynamic "home_directory_mappings" {
    for_each = var.restricted_home ? [1] : []

    content {
      entry  = "/"
      target = "/${var.s3_bucket_name}/$${Transfer:UserName}"
    }
  }

  tags = module.this.tags
}

resource "aws_transfer_ssh_key" "default" {
  for_each = local.enabled ? var.sftp_users : {}

  server_id = join("", aws_transfer_server.default[*].id)

  user_name = each.value.user_name
  body      = each.value.public_key

  depends_on = [
    aws_transfer_user.default
  ]
}

resource "aws_eip" "sftp" {
  count = local.enabled && var.eip_enabled ? length(var.subnet_ids) : 0

  vpc = local.is_vpc
}

module "security_group" {
  source  = "cloudposse/security-group/aws"
  version = "0.3.1"

  use_name_prefix = var.security_group_use_name_prefix
  rules           = var.security_group_rules
  description     = var.security_group_description
  vpc_id          = local.is_vpc ? var.vpc_id : null

  enabled = local.security_group_enabled
  context = module.this.context
}

# Custom Domain
resource "aws_route53_record" "main" {
  count = local.enabled && length(var.domain_name) > 0 && length(var.zone_id) > 0 ? 1 : 0

  name    = var.domain_name
  zone_id = var.zone_id
  type    = "CNAME"
  ttl     = "300"

  records = [
    join("", aws_transfer_server.default[*].endpoint)
  ]
}

module "logging_label" {
  source  = "cloudposse/label/null"
  version = "0.24.1"

  attributes = ["transfer", "cloudwatch"]

  context = module.this.context
}

data "aws_iam_policy_document" "assume_role_policy" {
  count = local.enabled ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["transfer.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "s3_access_for_sftp_users" {
  for_each = local.enabled ? local.user_names_map : {}

  statement {
    sid    = "AllowListingOfUserFolder"
    effect = "Allow"

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      "arn:aws:s3:::${var.s3_bucket_name}",
      "arn:aws:s3:::${var.s3_bucket_name}/${each.value}/*"
    ]
  }

  statement {
    sid    = "HomeDirObjectAccess"
    effect = "Allow"

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
      "s3:GetObjectVersion",
      "s3:GetObjectACL",
      "s3:PutObjectACL"
    ]

    resources = [
      "arn:aws:s3:::${var.s3_bucket_name}/${each.value}/*"
     ]
  }

}

data "aws_iam_policy_document" "kms_access_for_sftp_users" {
  count = local.kms_enabled ? 1 : 0

  statement {
    sid    = "KMSKeyAccess"
    effect = "Allow"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]

    resources = [
      join("", [var.kms_key_arn])
    ]
  }
}

data "aws_iam_policy_document" "transfer_service_policy_default" {
  count = local.scope_down_policy_enabled ? 1 : 0

  statement {
    sid    = "AllowListingOfUserFolder"
    effect = "Allow"

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      "arn:aws:s3:::${var.s3_bucket_name}",
      "arn:aws:s3:::${var.s3_bucket_name}/*"
    ]
  }

  statement {
    sid    = "HomeDirObjectAccess"
    effect = "Allow"

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
      "s3:GetObjectVersion",
      "s3:GetObjectACL",
      "s3:PutObjectACL"
    ]

    resources = [
      "arn:aws:s3:::${var.s3_bucket_name}/*"
    ]
  }
}

data "aws_iam_policy_document" "session_policy_default" {
  count = local.scope_down_policy_enabled ? 1 : 0

  # This uses Transfer Service automatic interpolations, so we escape the terraform interpolation with double $
  # See https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/transfer_user#argument-reference
  statement {
    sid    = "AllowListingOfUserFolder"
    effect = "Allow"

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      "arn:aws:s3:::$${transfer:HomeBucket}"
    ]
    condition {
      test = "StringLike"
      values = [
        "$${transfer:HomeFolder}/*",
        "$${transfer:HomeFolder}"
      ]
      variable = "s3:prefix"
    }
  }

  statement {
    sid    = "HomeDirObjectAccess"
    effect = "Allow"

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
      "s3:GetObjectVersion",
      "s3:GetObjectACL",
      "s3:PutObjectACL"
    ]

    # Note: we assume that users have their home directories set to include a trailing slash, to signify that it is a directory
    # If not, you need to provide your own policy
    resources = [
      "arn:aws:s3:::$${transfer:HomeDirectory}*"
    ]
  }
}

data "aws_iam_policy_document" "s3_kms_access_for_sftp_users" {
  for_each = local.multi_role_policy_enabled ? local.user_names_map : {}

  source_policy_documents = concat([data.aws_iam_policy_document.s3_access_for_sftp_users[index(local.user_names, each.value)].json],
    local.kms_enabled ? [data.aws_iam_policy_document.kms_access_for_sftp_users[0].json] : []
  )
}

data "aws_iam_policy_document" "transfer_kms_access_for_sftp_users" {
  count = local.scope_down_policy_enabled ? 1 : 0

  source_policy_documents = concat([data.aws_iam_policy_document.transfer_service_policy_default[0].json],
    local.kms_enabled ? [data.aws_iam_policy_document.kms_access_for_sftp_users[0].json] : []
  )
}

data "aws_iam_policy_document" "session_kms_access_for_sftp_users" {
  count = local.scope_down_policy_enabled ? 1 : 0

  source_policy_documents = concat([data.aws_iam_policy_document.session_policy_default[0].json],
    local.kms_enabled ? [data.aws_iam_policy_document.kms_access_for_sftp_users[0].json] : []
  )
}

data "aws_iam_policy_document" "logging" {
  count = local.enabled ? 1 : 0

  statement {
    sid    = "CloudWatchAccessForAWSTransfer"
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:CreateLogGroup",
      "logs:PutLogEvents"
    ]

    resources = ["*"]
  }
}

module "iam_label" {
  for_each = local.enabled ? local.user_names_map : {}

  source  = "cloudposse/label/null"
  version = "0.24.1"

  attributes = local.scope_down_policy_enabled ? ["transfer", "s3"] : ["transfer", "s3", each.value]

  context = module.this.context
}

resource "aws_iam_policy" "s3_access_for_sftp_users" {
  for_each = local.multi_role_policy_enabled ? local.user_names_map : {}

  name   = module.iam_label[index(local.user_names, each.value)].id
  policy = data.aws_iam_policy_document.s3_kms_access_for_sftp_users[index(local.user_names, each.value)].json
}

resource "aws_iam_role" "s3_access_for_sftp_users" {
  for_each = local.multi_role_policy_enabled ? local.user_names_map : {}

  name = module.iam_label[index(local.user_names, each.value)].id

  assume_role_policy  = join("", data.aws_iam_policy_document.assume_role_policy[*].json)
  managed_policy_arns = [aws_iam_policy.s3_access_for_sftp_users[index(local.user_names, each.value)].arn]
}

resource "aws_iam_policy" "transfer_service_policy_default" {
  count = local.scope_down_policy_enabled ? 1 : 0
  name   = module.iam_label[0].id
  policy = data.aws_iam_policy_document.transfer_kms_access_for_sftp_users[0].json
}

resource "aws_iam_role" "transfer_service_policy_default" {
  count = local.scope_down_policy_enabled ? 1 : 0
  name = module.iam_label[0].id

  assume_role_policy  = join("", data.aws_iam_policy_document.assume_role_policy[*].json)
  managed_policy_arns = [aws_iam_policy.transfer_service_policy_default[0].arn]
}

resource "aws_iam_policy" "logging" {
  count = local.enabled ? 1 : 0

  name   = module.logging_label.id
  policy = join("", data.aws_iam_policy_document.logging[*].json)
}

resource "aws_iam_role" "logging" {
  count = local.enabled ? 1 : 0

  name                = module.logging_label.id
  assume_role_policy  = join("", data.aws_iam_policy_document.assume_role_policy[*].json)
  managed_policy_arns = [join("", aws_iam_policy.logging[*].arn)]
}
