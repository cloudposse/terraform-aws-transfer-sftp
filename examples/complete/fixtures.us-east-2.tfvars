region = "us-east-2"

namespace = "eg"

environment = "ue2"

stage = "test"

name = "example"

sftp_users = {
  "brad" = {
    user_name  = "brad",
    public_key = "publickey"
  },
  "kenny" = {
    user_name  = "kenny",
    public_key = "publickey"
  }
}
