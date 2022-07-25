variable "security_group_enabled" {
  type        = bool
  default     = true
  description = <<-EOT
  DEPRECATED: Use `create_security_group` instead.
  Whether to create default Security Group for AWS Transfer Server."
  EOT
}

variable "security_group_use_name_prefix" {
  type        = bool
  default     = false
  description = <<-EOT
  DEPRECATED: Use `security_group_name` instead.
  Whether to create a default Security Group with unique name beginning with the normalized prefix."
  EOT
}

variable "security_group_rules" {
  type = list(any)
  default = [
    {
      type        = "ingress"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow inbound traffic"
    }
  ]
  description = <<-EOT
    DEPRECATED: Use `additional_security_group_rules` instead.
    A list of maps of Security Group rules. 
    The values of map is fully complated with `aws_security_group_rule` resource. 
    To get more info see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule .
  EOT
}