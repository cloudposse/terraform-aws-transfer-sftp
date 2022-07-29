region = "us-east-2"

namespace = "eg"

environment = "ue2"

stage = "test"

name = "sftp"

availability_zones = ["us-east-2a", "us-east-2b"]

cidr_block = "10.0.0.0/16"

sftp_users = {
  "brad" = {
    user_name  = "brad",
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDCziM50ppY+lb95xwkfPmz9i9fjcZ+jxut1hwhGJrnLUED26/tmlgSS4OaTi9jDHLeHaRcSRvKJObwsfR3tYH45YDGF4kwjv+OyMnsepPXrBX9cI0Bq0aH39BBBdRICbEEyoJdNhLH8MRGddtJ6G2uXZV9AvVqr01NokayLVO1WvCUi8bSvAHe8+KDE/odVsoOTRnKVK6Ov2LtJuff5OF9LmsY+vAtPkGZF9hfoB6k8irUqG8f8hx7ZooKUFZv9k9F4gvEXen9e/DdJ2VZHaL1LGUtNGNsrwgvgaQlbgqyuiIL91JYDrCR6ZwuI42CPQfqWwUfeO0W9roE0E7v/04+76TSVmHA1arqAETDmpAqvQNGP4uxml3u7ZqUD82At9u0yAgTX+xS4qnrg383e3ZXoTTa6q3ms/z75NHlttSRaN4Yf260RmTHDlyg4i+8qJasnhOcMLgMwuS7iywUZrIkmmpr6FQk3XwvUGbKpwdxepF4OFz5aMAouF17ZOajv1vxSDhTRQZzHbT18HFDNHDbHm61XwEeuurFxxO6TiQw8rSRrcUBmN8Mk9mVvC2FMRLJt3SonTyDpzcvQlcES6eSvXM6C/qy4xYB4wA3vZLgSswy8dGK2PlwszsqeT4WtA/6kC6i+0w30i2xxBCjKwSTNQzPUz/aVE+QDsN32f1i/Q== developer@developers-MacBook-Pro.local"
  },
  "kenny" = {
    user_name  = "kenny",
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCYN8IRq10gKJj5/y2IHYFFRXHctJ+VblcsOnwvsbUIB+PKMLLWd5ySpW30s8OFVcxpMu2VXzXVKRGGbOUbZEN7MqH9xkW8eV6tSfXsZK2osLdIQ3QG3eSyoN4gPFlDBkZSzmkb2oaaclGPGRezbzDnp+oz8IiC5ZE8aprq3Xk850fifIEEOhJtVsrL84uwgx4LGZMMQmLdf6xm2SMSMx53zDPtSnlSeMlC2qUz6LBC41gwObQDoh0j3svsENf8FS8iIkdX50NaRoZvhJU0Oud5A7bj3zz0xtKn6uQZnL9hb6ttvp2/mNe1CKBZt9hUdrn4SHPs0sbWYbQLTzp+9okcg8LCe7qnFdHH7xQGp17SAgi5f91RPOUWtqvkOC5yoVaveR82KZObU+HSCfT/PObLjdUDtWrZABp4VM/u5t9Fn6BQ+eRSAiCIqLQlizs9kpKO8LYX7CagxRJz8KtRXfhndA3nTFq35vml8rD5hKsTrtbSkycmytQZ8TF7IwuN0amRfZ7Iwb3/eLTEv6jp5PKKVprBvnjDH1ipn/AwidsKrbCCVquKg0X/7rwVLrvMuYAtlxPLqjqZpvfTwXBwLlHTEuCvuh/Y/TpjJqqxCnbY/6R4TcabHVGsA4b1kVajRbvVPZPGVcWs+XvycO4Y8KR/hZZGGxK16SVFGbrnhX1D2Q== developer@developers.local"

  }
}
