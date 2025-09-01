provider "aws" {
  region = var.region
}

provider "awsutils" {
  region = var.region
}


module "vpc" {
  source  = "cloudposse/vpc/aws"
  version = "2.3.0"

  ipv4_primary_cidr_block = var.cidr_block

  context = module.this.context
}

module "subnets" {
  source  = "cloudposse/dynamic-subnets/aws"
  version = "2.4.2"

  availability_zones   = var.availability_zones
  vpc_id               = module.vpc.vpc_id
  igw_id               = [module.vpc.igw_id]
  ipv4_cidr_block      = [module.vpc.vpc_cidr_block]
  max_nats             = 1
  nat_gateway_enabled  = true
  nat_instance_enabled = false

  context = module.this.context
}

module "security_group" {
  source  = "cloudposse/security-group/aws"
  version = "2.2.0"

  vpc_id = module.vpc.vpc_id
  rules = [
    {
      type        = "ingress"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  context = module.this.context
}

module "s3_bucket" {
  source             = "cloudposse/s3-bucket/aws"
  version            = "4.10.0"
  acl                = "private"
  enabled            = true
  user_enabled       = false
  versioning_enabled = false
  force_destroy      = true

  context = module.this.context
}


module "sftp" {
  source = "../.."

  eip_enabled            = true
  s3_bucket_name         = module.s3_bucket.bucket_id
  sftp_users             = var.sftp_users
  subnet_ids             = [module.subnets.public_subnet_ids[1]]
  vpc_id                 = module.vpc.vpc_id
  restricted_home        = true
  vpc_security_group_ids = [module.security_group.id]

  context = module.this.context
}
