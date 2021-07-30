provider "aws" {
  region = var.region
}

module "vpc" {
  source  = "cloudposse/vpc/aws"
  version = "0.25.0"

  namespace  = "eg"
  stage      = "test"
  name       = "app"
  cidr_block = "10.0.0.0/16"
}

module "dynamic_subnets" {
  source             = "cloudposse/dynamic-subnets/aws"
  version            = "0.39.3"
  namespace          = "eg"
  stage              = "test"
  name               = "app"
  availability_zones = ["us-east-2a", "us-east-2b"]
  vpc_id             = module.vpc.vpc_id
  igw_id             = module.vpc.igw_id
  cidr_block         = "10.0.0.0/16"
}

module "security_group" {
  source          = "cloudposse/security-group/aws"
  version         = "0.3.1"
  environment     = "test"
  id_length_limit = null
  label_key_case  = "title"
  name            = "allow_sftp"
  namespace       = "eg"
  vpc_id          = module.vpc.vpc_id
  rules = [
    {
      type        = "ingress"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
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

  sftp_users             = var.sftp_users
  vpc_id                 = module.vpc.vpc_id
  subnet_ids             = module.dynamic_subnets.public_subnet_ids
  vpc_security_group_ids = [module.security_group.id]

  s3_bucket_name = module.s3_bucket.bucket_id

  context = module.this.context
}
