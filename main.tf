locals {
  enabled = module.this.enabled

  is_vpc = var.vpc_id != null
}

resource "aws_transfer_server" "default" {
  identity_provider_type = "SERVICE_MANAGED"
  protocols              = ["SFTP"]
  domain                 = var.domain
  endpoint_type          = local.is_vpc ? "VPC" : "PUBLIC"
  force_destroy          = var.force_destroy
  security_policy_name = var.security_policy_name
  logging_role = aws_iam_role.logging.arn

  dynamic "endpoint_details" {
    for_each = local.is_vpc ? [1] : []

    content {
      address_allocation_ids = var.address_allocation_ids
      security_group_ids = var.vpc_security_group_ids
      subnet_ids = var.subnet_ids
      vpc_endpoint_id = var.vpc_endpoint_id
      vpc_id = var.vpc_id
    }
  }

  tags = module.this.tags
}

resource "aws_transfer_user" "default" {
  for_each = local.enabled ? var.sftp_users : {}

  server_id = aws_transfer_server.default.id
  role      = aws_iam_role.default.arn

  user_name = each.value.user_name

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
  count   = length(var.domain_name) > 0 && length(var.zone_id) > 0 ? 1 : 0
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
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["transfer.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "allows_s3" {
  statement {
    sid    = "S3AccessForAWSTransferusers"
    effect = "Allow"

    actions = ["s3:*"]

    resources = [
      "arn:aws:s3:::*"
    ]
  }
}

data "aws_iam_policy_document" "logging" {
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
  name   = module.iam_label.id
  policy = data.aws_iam_policy_document.allows_s3.json
}

resource "aws_iam_policy" "logging" {
  name   = module.logging_label.id
  policy = data.aws_iam_policy_document.logging.json
}

resource "aws_iam_role" "default" {
  name                = module.iam_label.id
  assume_role_policy  = data.aws_iam_policy_document.assume_role_policy.json
  managed_policy_arns = [aws_iam_policy.default.arn]
}

resource "aws_iam_role" "logging" {
  name                = module.logging_label.id
  assume_role_policy  = data.aws_iam_policy_document.assume_role_policy.json
  managed_policy_arns = [aws_iam_policy.logging.arn]
}
