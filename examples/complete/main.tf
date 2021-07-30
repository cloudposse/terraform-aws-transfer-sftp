provider "aws" {
  region = var.region
}

module "s3_bucket" {
  source             = "cloudposse/s3-bucket/aws"
  version            = "0.41.0"
  acl                = "private"
  enabled            = true
  user_enabled       = false
  versioning_enabled = false

  context = module.this.context
}

module "example" {
  source = "../.."

  sftp_users = var.sftp_users

  s3_bucket_name = module.s3_bucket.bucket_id

  context = module.this.context
}
