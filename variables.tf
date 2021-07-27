variable "sftp_users" {
  type = map(object({
    user_name = string,
    public_key = string
  }))
  
  default = []
  description = "List of SFTP usernames and public keys"
}