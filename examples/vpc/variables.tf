variable "region" {
  type = string
}

variable "sftp_users" {
  type = map(object({
    user_name  = string,
    public_key = string
  }))
  description = "The value which will be passed to the example module"
}
