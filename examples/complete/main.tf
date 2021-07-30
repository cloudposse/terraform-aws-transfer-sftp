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
  name               = "app"
  stage              = "test"
  namespace          = "eg"
}

module "example" {
  source = "../.."

  region = var.region

  sftp_users = var.sftp_users

  s3_bucket_name = module.s3_bucket.bucket_id

  context = module.this.context
}
