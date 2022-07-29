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
    DEPRECATED: Use `security_group_name` instead to set a prefix or set `create_before_destroy` to true which will use a prefix.
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

variable "vpc_security_group_ids" {
  type        = list(string)
  default     = []
  description = <<-EOT
    DEPRECATED: Use `associated_security_group_ids` instead.
    A list of security groups IDs that are available to attach to your server's endpoint. If no security groups are specified, the VPC's default security groups are automatically assigned to your endpoint. This property can only be used when endpoint_type is set to VPC.
  EOT
}
