provider "aws" {
  region = var.region
}

provider "awsutils" {
  region = var.region
}

module "s3_bucket" {
  source  = "cloudposse/s3-bucket/aws"
  version = "4.10.0"

  for_each = toset(["home", "extra"])

  acl                = "private"
  enabled            = true
  user_enabled       = false
  versioning_enabled = false
  force_destroy      = true

  attributes = [each.value]

  context = module.this.context
}

module "sftp" {
  source = "../.."

  sftp_users = merge(var.sftp_users, {
    kenny = merge({
      s3_bucket_name = module.s3_bucket["extra"].bucket_id
    }, var.sftp_users["kenny"])
  })

  s3_bucket_name = module.s3_bucket["home"].bucket_id

  context = module.this.context
}
