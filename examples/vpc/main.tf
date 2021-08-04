provider "aws" {
  region = var.region
}

module "vpc" {
  source  = "cloudposse/vpc/aws"
  version = "0.25.0"

  cidr_block = "10.0.0.0/16"

  context = module.this.context
}

module "dynamic_subnets" {
  source  = "cloudposse/dynamic-subnets/aws"
  version = "0.39.3"

  availability_zones = ["us-east-2a", "us-east-2b"]
  vpc_id             = module.vpc.vpc_id
  igw_id             = module.vpc.igw_id
  cidr_block         = "10.0.0.0/16"

  context = module.this.context
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

  eip_enabled    = true
  s3_bucket_name = module.s3_bucket.bucket_id
  sftp_users     = var.sftp_users
  subnet_ids     = [module.dynamic_subnets.public_subnet_ids[0]]
  vpc_id         = module.vpc.vpc_id
  allowed_cidrs  = ["0.0.0.0/0"]

  context = module.this.context
}
