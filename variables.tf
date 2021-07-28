variable "region" {
  type    = string
  default = "us-east-1"
}

variable "sftp_users" {
  type = map(object({
    user_name  = string,
    public_key = string
  }))

  default     = {}
  description = "List of SFTP usernames and public keys"
}

variable "force_destroy" {
  type        = bool
  default     = false
  description = "Forces the AWS Transfer Server to be destroyed"
}

variable "iam_attributes" {
  type        = list(string)
  description = "Additional attributes to add to the IDs of the IAM role and policy"
  default     = []
}