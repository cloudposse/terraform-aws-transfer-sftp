variable "region" {
  type    = string
}

variable "domain" {
  type = string
  description = "Where your files are stored. S3 or EFS"
  default = "S3"
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
  description = "Forces the AWS Transfer Server to be destroyed"
  default     = false
}

variable "iam_attributes" {
  type        = list(string)
  description = "Additional attributes to add to the IDs of the IAM role and policy"
  default     = []
}

# Variables used when deploying to VPC
variable "vpc_id" {
  type = string
  description = "VPC ID that the AWS Transfer Server will be deployed to"
  default = null
}

variable "address_allocation_ids" {
  type = list(string)  
  description = "A list of address allocation IDs that are required to attach an Elastic IP address to your SFTP server's endpoint. This property can only be used when endpoint_type is set to VPC."
  default = []
}

variable "vpc_security_group_ids" {
  type = list(string)
  description = "A list of security groups IDs that are available to attach to your server's endpoint. If no security groups are specified, the VPC's default security groups are automatically assigned to your endpoint. This property can only be used when endpoint_type is set to VPC."
  default = []
}

variable "subnet_ids" {
  type = list(string)  
  description = "A list of subnet IDs that are required to host your SFTP server endpoint in your VPC. This property can only be used when endpoint_type is set to VPC."
  default = []
}

variable "vpc_endpoint_id" {
  type = string
  description = "The ID of the VPC endpoint. This property can only be used when endpoint_type is set to VPC_ENDPOINT"
  default = null
}

variable "security_policy_name" {
  type = string
  description = "Specifies the name of the security policy that is attached to the server. Possible values are TransferSecurityPolicy-2018-11, TransferSecurityPolicy-2020-06, and TransferSecurityPolicy-FIPS-2020-06. Default value is: TransferSecurityPolicy-2018-11."  
  default = "TransferSecurityPolicy-2018-11"
}

variable "domain_name" {
  type = string
  description = "Domain to use when connecting to the SFTP endpoint"
  default = ""
}

variable "zone_id" {
  type = string
  description = "Route53 Zone ID to add the CNAME"
  default = ""
}