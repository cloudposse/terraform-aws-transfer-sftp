locals {
  enabled = module.this.enabled

  s3_arn_prefix = "arn:${one(data.aws_partition.default[*].partition)}:s3:::"

  is_vpc = var.vpc_id != null

  user_names_map = {
    for user, val in var.sftp_users :
    user => merge(val, {
      s3_bucket_arn = val.s3_bucket_name != null ? "${local.s3_arn_prefix}${val.s3_bucket_name}" : one(data.aws_s3_bucket.landing[*].arn)
      # Mapping targets have the form "/<bucket>/<prefix>", stripped of the surrounding slashes
      mapping_targets = [
        for m in coalesce(val.home_directory_mappings, []) : trim(m.target, "/")
      ]
    })
  }

  # When custom home_directory_mappings are given, S3 access is scoped to the mapping targets
  # instead of the default "<bucket>/<user_name>" folder.
  user_s3_access = {
    for user, val in local.user_names_map :
    user => length(val.mapping_targets) > 0 ? {
      bucket_arns = distinct([for t in val.mapping_targets : "${local.s3_arn_prefix}${split("/", t)[0]}"])
      object_arns = [for t in val.mapping_targets : "${local.s3_arn_prefix}${t}/*"]
      } : {
      bucket_arns = [val.s3_bucket_arn]
      object_arns = [var.restricted_home ? "${val.s3_bucket_arn}/${val.user_name}/*" : "${val.s3_bucket_arn}/*"]
    }
  }

  ssh_keys = {
    for item in flatten([
      for val in var.sftp_users : [
        for key in val.public_keys : {
          user_name  = val.user_name
          public_key = key
        }
      ]
    ]) : md5("${item.user_name}#${item.public_key}") => item
  }
}

data "aws_partition" "default" {
  count = local.enabled ? 1 : 0
}

data "aws_s3_bucket" "landing" {
  count = local.enabled ? 1 : 0

  bucket = var.s3_bucket_name
}

resource "aws_transfer_server" "default" {
  count = local.enabled ? 1 : 0

  identity_provider_type           = "SERVICE_MANAGED"
  protocols                        = ["SFTP"]
  domain                           = var.domain
  endpoint_type                    = local.is_vpc ? "VPC" : "PUBLIC"
  force_destroy                    = var.force_destroy
  security_policy_name             = var.security_policy_name
  logging_role                     = join("", aws_iam_role.logging[*].arn)
  pre_authentication_login_banner  = var.pre_authentication_login_banner
  post_authentication_login_banner = var.post_authentication_login_banner

  dynamic "endpoint_details" {
    for_each = local.is_vpc ? [1] : []

    content {
      subnet_ids             = var.subnet_ids
      security_group_ids     = var.vpc_security_group_ids
      vpc_id                 = var.vpc_id
      address_allocation_ids = var.eip_enabled ? aws_eip.sftp[*].id : var.address_allocation_ids
    }
  }

  tags = module.this.tags
}

resource "aws_transfer_user" "default" {
  for_each = local.enabled ? var.sftp_users : {}

  server_id = join("", aws_transfer_server.default[*].id)
  role      = aws_iam_role.s3_access_for_sftp_users[each.value.user_name].arn

  user_name = each.value.user_name

  # Custom home_directory_mappings always imply a LOGICAL home directory
  home_directory_type = coalesce(
    each.value.home_directory_type,
    var.restricted_home || each.value.home_directory_mappings != null ? "LOGICAL" : "PATH"
  )
  # home_directory is only honored by AWS for PATH home directories
  home_directory = var.restricted_home || each.value.home_directory_mappings != null ? null : (
    coalesce(
      each.value.home_directory,
      "/${coalesce(each.value.s3_bucket_name, var.s3_bucket_name)}"
    )
  )

  dynamic "home_directory_mappings" {
    for_each = each.value.home_directory_mappings != null ? each.value.home_directory_mappings : (
      var.restricted_home ? [{
        entry = "/"
        # Specifically do not use $${Transfer:UserName} since subsequent terraform plan/applies will try to revert
        # the value back to $${Tranfer:*} value
        target = "/${coalesce(each.value.s3_bucket_name, var.s3_bucket_name)}/${each.value.user_name}"
      }] : []
    )

    content {
      entry  = home_directory_mappings.value.entry
      target = home_directory_mappings.value.target
    }
  }

  tags = module.this.tags
}

resource "aws_transfer_ssh_key" "default" {
  for_each = local.enabled ? local.ssh_keys : {}

  server_id = join("", aws_transfer_server.default[*].id)

  user_name = each.value.user_name
  body      = each.value.public_key

  depends_on = [
    aws_transfer_user.default
  ]
}

resource "aws_eip" "sftp" {
  count = local.enabled && var.eip_enabled ? length(var.subnet_ids) : 0

  domain = "vpc"

  tags = module.this.tags
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
  version = "0.25.0"

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

    resources = local.user_s3_access[each.key].bucket_arns
  }

  statement {
    sid    = "HomeDirObjectAccess"
    effect = "Allow"

    actions = coalesce(each.value.bucket_permissions, [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
      "s3:GetObjectVersion",
      "s3:GetObjectACL",
      "s3:PutObjectACL"
    ])

    resources = local.user_s3_access[each.key].object_arns
  }
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
  version = "0.25.0"

  attributes = ["transfer", "s3", each.value.user_name]

  context = module.this.context
}

resource "aws_iam_policy" "s3_access_for_sftp_users" {
  for_each = local.enabled ? local.user_names_map : {}

  name   = module.iam_label[each.value.user_name].id
  policy = data.aws_iam_policy_document.s3_access_for_sftp_users[each.value.user_name].json

  tags = module.this.tags
}

resource "aws_iam_role" "s3_access_for_sftp_users" {
  for_each = local.enabled ? local.user_names_map : {}

  name               = module.iam_label[each.value.user_name].id
  assume_role_policy = join("", data.aws_iam_policy_document.assume_role_policy[*].json)

  tags = module.this.tags
}

resource "aws_iam_role_policy_attachment" "s3_access_for_sftp_users" {
  for_each = local.enabled ? local.user_names_map : {}

  role       = aws_iam_role.s3_access_for_sftp_users[each.value.user_name].name
  policy_arn = aws_iam_policy.s3_access_for_sftp_users[each.value.user_name].arn
}

resource "aws_iam_policy" "logging" {
  count = local.enabled ? 1 : 0

  name   = module.logging_label.id
  policy = join("", data.aws_iam_policy_document.logging[*].json)

  tags = module.this.tags
}

resource "aws_iam_role" "logging" {
  count = local.enabled ? 1 : 0

  name               = module.logging_label.id
  assume_role_policy = join("", data.aws_iam_policy_document.assume_role_policy[*].json)

  tags = module.this.tags
}

resource "aws_iam_role_policy_attachment" "logging" {
  count = local.enabled ? 1 : 0

  role       = one(aws_iam_role.logging[*].name)
  policy_arn = one(aws_iam_policy.logging[*].arn)
}
