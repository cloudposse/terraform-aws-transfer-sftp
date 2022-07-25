locals {
  enabled = module.this.enabled

  is_vpc                 = var.vpc_id != null
  security_group_enabled = module.this.enabled && var.create_security_group
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
  role      = aws_iam_role.s3_access_for_sftp_users[index(local.user_names, each.value.user_name)].arn

  user_name = each.value.user_name

  home_directory_type = var.restricted_home ? "LOGICAL" : "PATH"
  home_directory      = !var.restricted_home ? "/${var.s3_bucket_name}" : null

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

  tags = module.this.tags
}

module "security_group" {
  source  = "cloudposse/security-group/aws"
  version = "1.0.1"

  enabled                       = local.security_group_enabled
  security_group_name           = var.security_group_name
  create_before_destroy         = var.security_group_create_before_destroy
  security_group_create_timeout = var.security_group_create_timeout
  security_group_delete_timeout = var.security_group_delete_timeout

  security_group_description = var.security_group_description
  allow_all_egress           = true
  rules                      = var.additional_security_group_rules
  rule_matrix = [
    {
      source_security_group_ids = var.allowed_security_group_ids
      cidr_blocks               = var.allowed_cidr_blocks
      rules = [
        {
          key         = "in"
          type        = "ingress"
          from_port   = 22
          to_port     = 22
          protocol    = "tcp"
          description = "Allow ingress EFS traffic"
        }
      ]
    }
  ]
  vpc_id = local.is_vpc ? var.vpc_id : null

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

    resources = [
      join("", data.aws_s3_bucket.landing[*].arn)
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
      var.restricted_home ? "${join("", data.aws_s3_bucket.landing[*].arn)}/${each.value}/*" : "${join("", data.aws_s3_bucket.landing[*].arn)}/*"
    ]
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

  attributes = ["transfer", "s3", each.value]

  context = module.this.context
}

resource "aws_iam_policy" "s3_access_for_sftp_users" {
  for_each = local.enabled ? local.user_names_map : {}

  name   = module.iam_label[index(local.user_names, each.value)].id
  policy = data.aws_iam_policy_document.s3_access_for_sftp_users[index(local.user_names, each.value)].json

  tags = module.this.tags
}

resource "aws_iam_role" "s3_access_for_sftp_users" {
  for_each = local.enabled ? local.user_names_map : {}

  name = module.iam_label[index(local.user_names, each.value)].id

  assume_role_policy  = join("", data.aws_iam_policy_document.assume_role_policy[*].json)
  managed_policy_arns = [aws_iam_policy.s3_access_for_sftp_users[index(local.user_names, each.value)].arn]

  tags = module.this.tags
}

resource "aws_iam_policy" "logging" {
  count = local.enabled ? 1 : 0

  name   = module.logging_label.id
  policy = join("", data.aws_iam_policy_document.logging[*].json)

  tags = module.this.tags
}

resource "aws_iam_role" "logging" {
  count = local.enabled ? 1 : 0

  name                = module.logging_label.id
  assume_role_policy  = join("", data.aws_iam_policy_document.assume_role_policy[*].json)
  managed_policy_arns = [join("", aws_iam_policy.logging[*].arn)]

  tags = module.this.tags
}
