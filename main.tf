locals {
  enabled = module.this.enabled

  is_vpc = var.vpc_id != null
}

data "aws_s3_bucket" "landing" {
  bucket = var.s3_bucket_name
}

resource "aws_transfer_server" "default" {
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
      subnet_ids         = var.subnet_ids
      security_group_ids = var.vpc_security_group_ids
      vpc_id             = var.vpc_id
    }
  }

  tags = module.this.tags
}

resource "aws_transfer_user" "default" {
  for_each = local.enabled ? var.sftp_users : {}

  server_id = aws_transfer_server.default.id
  role      = join("", aws_iam_role.default[*].arn)

  home_directory = "/${var.s3_bucket_name}/${each.value.user_name}"
  user_name      = each.value.user_name

  tags = module.this.tags
}

resource "aws_transfer_ssh_key" "default" {
  for_each = local.enabled ? var.sftp_users : {}

  server_id = aws_transfer_server.default.id

  user_name = each.value.user_name
  body      = each.value.public_key

  depends_on = [
    aws_transfer_user.default
  ]
}

# Custom Domain
resource "aws_route53_record" "main" {
  count = local.enabled && length(var.domain_name) > 0 && length(var.zone_id) > 0 ? 1 : 0

  name    = var.domain_name
  zone_id = var.zone_id
  type    = "CNAME"
  ttl     = "300"

  records = [
    aws_transfer_server.default.endpoint
  ]
}

# IAM
module "iam_label" {
  source  = "cloudposse/label/null"
  version = "0.24.1"

  attributes = ["transfer", "s3"]

  context = module.this.context
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

data "aws_iam_policy_document" "allows_s3" {
  count = local.enabled ? 1 : 0

  statement {
    sid    = "AllowListingOfUserFolder"
    effect = "Allow"

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      data.aws_s3_bucket.landing.arn
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
      "${data.aws_s3_bucket.landing.arn}/*"
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

resource "aws_iam_policy" "default" {
  count = local.enabled ? 1 : 0

  name   = module.iam_label.id
  policy = join("", data.aws_iam_policy_document.allows_s3[*].json)
}

resource "aws_iam_policy" "logging" {
  count = local.enabled ? 1 : 0

  name   = module.logging_label.id
  policy = join("", data.aws_iam_policy_document.logging[*].json)
}

resource "aws_iam_role" "default" {
  count = local.enabled ? 1 : 0

  name                = module.iam_label.id
  assume_role_policy  = join("", data.aws_iam_policy_document.assume_role_policy[*].json)
  managed_policy_arns = [join("", aws_iam_policy.default[*].arn)]
}

resource "aws_iam_role" "logging" {
  count = local.enabled ? 1 : 0

  name                = module.logging_label.id
  assume_role_policy  = join("", data.aws_iam_policy_document.assume_role_policy[*].json)
  managed_policy_arns = [join("", aws_iam_policy.logging[*].arn)]
}
