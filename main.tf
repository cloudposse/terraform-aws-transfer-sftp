locals {
  enabled             = module.this.enabled
}

module "iam_role_label" {
  source   = "cloudposse/label/null"
  version    = "0.24.1"
  enabled    = local.enabled
  
  attributes = ["role"]

  context = module.this.context
}

module "iam_policy_label" {
  source   = "cloudposse/label/null"
  version    = "0.24.1"
  enabled    = local.enabled
  
  attributes = ["policy"]

  context = module.this.context
}

resource "aws_transfer_server" "default" {
  identity_provider_type = "SERVICE_MANAGED"
  protocols = ["SFTP"] # SFTP, FTPS, FTP
  domain = "S3" # EFS, S3
  endpoint_type = "PUBLIC" # VPC, PUBLIC
  force_destroy = true

  tags = module.this.tags
}

resource "aws_transfer_user" "default" {
  for_each = var.sftp_users

  server_id = aws_transfer_server.default.id
  role      = aws_iam_role.default.arn
  
  user_name = each.value.user_name

  tags = module.this.tags
}

resource "aws_transfer_ssh_key" "default" {
  for_each = var.sftp_users

  server_id = aws_transfer_server.default.id
  
  user_name = each.value.user_name
  body      = each.value.public_key
}

resource "aws_iam_role" "default" {
  name = module.iam_role_label.id

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
        "Effect": "Allow",
        "Principal": {
            "Service": "transfer.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "default" {
  name = module.iam_policy_label.id
  role = aws_iam_role.default.id

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowFullAccesstoS3",
            "Effect": "Allow",
            "Action": [
                "s3:*"
            ],
            "Resource": "*"
        }
    ]
}
POLICY
}