provider "aws" {
  region = var.region
}

module "example" {
  source = "../.."

  region = var.region

  sftp_users = var.sftp_users

  context = module.this.context
}
