output "id" {
  description = "The null label ID passed to each resource"
  value       = module.this.enabled ? module.this.id : null
}

output "transfer_server_id" {
  description = "The ID of the Transfer Server"
  value       = module.this.enabled ? join("", aws_transfer_server.default.*.id) : null
}

output "transfer_endpoint" {
  description = "The endpoint of the Transfer Server"
  value       = module.this.enabled ? join("", aws_transfer_server.default.*.endpoint) : null
}

output "elastic_ips" {
  description = "Provisioned Elastic IPs"
  value       = module.this.enabled && var.eip_enabled ? aws_eip.sftp.*.id : null
}

output "s3_access_role_arns" {
  description = "Role ARNs for the S3 access"
  value       = { for idx, user in local.user_names_map : user => aws_iam_role.s3_access_for_sftp_users[idx].arn }
}
