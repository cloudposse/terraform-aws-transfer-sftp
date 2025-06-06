output "id" {
  description = "ID of the created example"
  value       = module.this.enabled ? module.this.id : null
}

output "transfer_endpoint" {
  description = "The endpoint of the Transfer Server"
  value       = module.this.enabled ? one(aws_transfer_server.default[*].endpoint) : null
}

output "elastic_ips" {
  description = "Provisioned Elastic IPs"
  value       = module.this.enabled && var.eip_enabled ? aws_eip.sftp[*].id : null
}

output "s3_access_role_arns" {
  description = "Role ARNs for the S3 access"
  value       = { for user, val in aws_iam_role.s3_access_for_sftp_users : user => val.arn }
}

output "endpoint_details" {
  description = "Endpoints details"
  value       = module.this.enabled ? one(aws_transfer_server.default[*].endpoint_details) : null
}

output "arn" {
  description = "ARN of the created Transfer Server"
  value       = module.this.enabled ? one(aws_transfer_server.default[*].arn) : null
}

output "host_key_fingerprint" {
  description = "The message-digest algorithm (MD5) hash of the Transfer Server's host key"
  value       = module.this.enabled ? one(aws_transfer_server.default[*].host_key_fingerprint) : null
}
