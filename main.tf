locals {
  enabled = module.this.enabled

  s3_arn_prefix = "arn:${one(data.aws_partition.default[*].partition)}:s3:::"

  is_vpc = var.vpc_id != null

  user_names = keys(var.sftp_users)

  user_names_map = {
    for user, val in var.sftp_users :
    user => merge(val, {
      home_dir_map = lookup(val, "home_directory_mappings", []) == null ? [] : lookup(val, "home_directory_mappings", [])
      s3_bucket_arn = lookup(val, "s3_bucket_name", null) != null ? "${local.s3_arn_prefix}${lookup(val, "s3_bucket_name")}" : one(data.aws_s3_bucket.landing[*].arn)
    })
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
      security_group_ids     = var.vpc_security_group_ids
      vpc_id                 = var.vpc_id
      address_allocation_ids = var.eip_enabled ? aws_eip.sftp.*.id : var.address_allocation_ids
    }
  }

  tags = module.this.tags
}

resource "aws_transfer_user" "default" {
  for_each = local.enabled ? var.sftp_users : {}

  server_id = join("", aws_transfer_server.default[*].id)
  role      = aws_iam_role.s3_access_for_sftp_users[each.value.user_name].arn

  user_name = each.value.user_name

  home_directory_type = lookup(each.value, "home_directory_type", null) != null ? lookup(each.value, "home_directory_type") : (var.restricted_home ? "LOGICAL" : "PATH")
  home_directory      = lookup(each.value, "home_directory", null) != null ? lookup(each.value, "home_directory") : (!var.restricted_home ? "/${lookup(each.value, "s3_bucket_name", var.s3_bucket_name)}" : null)

  dynamic "home_directory_mappings" {
    for_each = var.restricted_home ? (
      lookup(each.value, "home_directory_mappings", null) != null ? lookup(each.value, "home_directory_mappings") : [
        {
          entry = "/"
          # Specifically do not use $${Transfer:UserName} since subsequent terraform plan/applies will try to revert
          # the value back to $${Tranfer:*} value
          target = format("/%s/%s", lookup(each.value, "s3_bucket_name", var.s3_bucket_name), each.value.user_name)
        }
      ]
    ) : toset([])

    content {
      entry  = lookup(home_directory_mappings.value, "entry")
      target = lookup(home_directory_mappings.value, "target")
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
      each.value.s3_bucket_arn,
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

    resources = var.restricted_home ? (
      length(each.value.home_dir_map) > 0 ?
        [for hdm in each.value.home_dir_map :
          startswith(hdm.target, "/${substr(each.value.s3_bucket_arn, length(local.s3_arn_prefix), length(each.value.s3_bucket_arn))}") ?
        "${each.value.s3_bucket_arn}/${substr(hdm.target, length(each.value.s3_bucket_arn) - length(local.s3_arn_prefix) + 2, length(hdm.target))}/*" : "${each.value.s3_bucket_arn}/${hdm.target}/*"
      ] : ["${each.value.s3_bucket_arn}/${each.value.user_name}/*"]
    ) : [
    "${each.value.s3_bucket_arn}/*"
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

  name = module.iam_label[each.value.user_name].id

  assume_role_policy = join("", data.aws_iam_policy_document.assume_role_policy[*].json)

  tags = module.this.tags
}

resource "aws_iam_role_policy_attachment" "s3_access_for_sftp_users" {
  for_each   = aws_iam_policy.s3_access_for_sftp_users
  role       = aws_iam_role.s3_access_for_sftp_users[each.key].name
  policy_arn = each.value.arn
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
