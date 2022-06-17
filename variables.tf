variable "domain" {
  type        = string
  description = "Where your files are stored. S3 or EFS"
  default     = "S3"
}

variable "sftp_users" {
  type = map(object({
    user_name  = string,
    public_key = string,
    unix_uid   = number,
  }))

  default     = {}
  description = "List of SFTP usernames and public keys"
}

variable "restricted_home" {
  type        = bool
  description = "Restricts SFTP users so they only have access to their home directories."
  default     = true
}

variable "force_destroy" {
  type        = bool
  description = "Forces the AWS Transfer Server to be destroyed"
  default     = false
}

variable "s3_bucket_name" {
  type        = string
  description = "This is the bucket that the SFTP users will use when managing files"
}

# Variables used when deploying to VPC
variable "vpc_id" {
  type        = string
  description = "VPC ID that the AWS Transfer Server will be deployed to"
  default     = null
}

variable "address_allocation_ids" {
  type        = list(string)
  description = "A list of address allocation IDs that are required to attach an Elastic IP address to your SFTP server's endpoint. This property can only be used when endpoint_type is set to VPC."
  default     = []
}

variable "security_group_enabled" {
  type        = bool
  description = "Whether to create default Security Group for AWS Transfer Server."
  default     = true
}

variable "security_group_description" {
  type        = string
  default     = "AWS Transfer Server Security Group"
  description = "The Security Group description."
}

variable "security_group_use_name_prefix" {
  type        = bool
  default     = false
  description = "Whether to create a default Security Group with unique name beginning with the normalized prefix."
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
    A list of maps of Security Group rules. 
    The values of map is fully complated with `aws_security_group_rule` resource. 
    To get more info see https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule .
  EOT
}

variable "vpc_security_group_ids" {
  type        = list(string)
  description = "A list of security groups IDs that are available to attach to your server's endpoint. If no security groups are specified, the VPC's default security groups are automatically assigned to your endpoint. This property can only be used when endpoint_type is set to VPC."
  default     = []
}

variable "subnet_ids" {
  type        = list(string)
  description = "A list of subnet IDs that are required to host your SFTP server endpoint in your VPC. This property can only be used when endpoint_type is set to VPC."
  default     = []
}

variable "vpc_endpoint_id" {
  type        = string
  description = "The ID of the VPC endpoint. This property can only be used when endpoint_type is set to VPC_ENDPOINT"
  default     = null
}

variable "security_policy_name" {
  type        = string
  description = "Specifies the name of the security policy that is attached to the server. Possible values are TransferSecurityPolicy-2018-11, TransferSecurityPolicy-2020-06, and TransferSecurityPolicy-FIPS-2020-06. Default value is: TransferSecurityPolicy-2018-11."
  default     = "TransferSecurityPolicy-2018-11"
}

variable "domain_name" {
  type        = string
  description = "Domain to use when connecting to the SFTP endpoint"
  default     = ""
}

variable "zone_id" {
  type        = string
  description = "Route53 Zone ID to add the CNAME"
  default     = ""
}

variable "eip_enabled" {
  type        = bool
  description = "Whether to provision and attach an Elastic IP to be used as the SFTP endpoint. An EIP will be provisioned per subnet."
  default     = false
}

variable "host_key" {
  type        = string
  description = "Host key for ssh"
  default     = ""
}

variable "s3_bucket_permissions" {
  type        = list(string)
  description = "The permissions set on the backing bucket for the user's home directory. Defaults to not allow deletion or downloads."
  default     = ["s3:PutObject", "s3:PutObjectACL", "s3:GetObjectACL", "s3:GetObjectVersion"]
}

variable "vpc_private_subnet_ids" {
  type = list(string)
  description = "List of subnet ids"
  default = []
}

variable "lambda_zip" {
  type = string
  description = "filename of zip file of lambda function"
  default = ""
}

variable lambda_handler {
  type = string
  description = "entrypoint into lambda function"
  default = ""
}

variable kafka_rest_server {
  type = string
  description = "URI of kafka rest server"
  default = ""
}

variable kafka_queue {
  type = string
  description = "name of kafka queue to write to"
  default = ""
}

variable kafka_lambda_enabled {
  type = bool
  description = "If a kafka lambda is enabled as part of the workflow"
  default = true
}

