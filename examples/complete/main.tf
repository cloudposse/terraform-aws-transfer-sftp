provider "aws" {
  region = var.region
}

provider "awsutils" {
  region = var.region
}

module "s3_bucket" {
  source             = "cloudposse/s3-bucket/aws"
  version            = "2.0.3"
  acl                = "private"
  enabled            = true
  user_enabled       = false
  versioning_enabled = false
  force_destroy      = true

  context = module.this.context
}

module "example" {
  source = "../.."

  sftp_users = var.sftp_users

  s3_bucket_name = module.s3_bucket.bucket_id

  context = module.this.context
}
