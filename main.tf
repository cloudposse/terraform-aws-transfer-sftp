locals {
  enabled = module.this.enabled
}

resource "aws_transfer_server" "default" {
  identity_provider_type = "SERVICE_MANAGED"
  protocols              = ["SFTP"] # SFTP, FTPS, FTP
  domain                 = "S3"     # EFS, S3
  endpoint_type          = "PUBLIC" # VPC, PUBLIC
  force_destroy          = var.force_destroy

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

# IAM
module "iam_label" {
  source  = "cloudposse/label/null"
  version = "0.24.1"

  attributes = var.iam_attributes

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

resource "aws_iam_policy" "default" {
  name   = module.iam_label.id
  policy = data.aws_iam_policy_document.allows_s3.json
}

resource "aws_iam_role" "default" {
  name = module.iam_label.id
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  managed_policy_arns = [aws_iam_policy.default.arn]
}
