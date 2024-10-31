variable "region" {
  type = string
}

variable "availability_zones" {
  type        = list(string)
  description = "List of availability zones"
}

variable "ipv4_primary_cidr_block" {
  type        = string
  description = "CIDR for the VPC"
}

variable "sftp_users" {
  type = list(
    object({
      user_name      = string
      public_keys    = list(string)
      s3_bucket_name = optional(string)
    })
  )
  description = "List of SFTP usernames and public keys. The keys `user_name` and `public_keys` are required. The key `s3_bucket_name` is optional."
}