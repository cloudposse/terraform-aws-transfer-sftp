variable "region" {
  type        = string
  description = "AWS region"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of availability zones"
}

variable "cidr_block" {
  type        = string
  description = "CIDR for the VPC"
}

variable "sftp_users" {
  type = map(object({
    user_name  = string,
    public_key = string
  }))
  description = "The value which will be passed to the example module"
}
