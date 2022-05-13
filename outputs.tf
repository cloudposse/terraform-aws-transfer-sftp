output "id" {
  description = "ID of the created example"
  value       = module.this.enabled ? module.this.id : null
}

output "transfer_endpoint" {
  description = "The endpoint of the Transfer Server"
  value       = module.this.enabled ? join("", aws_transfer_server.default.*.endpoint) : null
}

output "elastic_ips" {
  description = "Provisioned Elastic IPs"
  value       = module.this.enabled && var.eip_enabled ? aws_eip.sftp.*.id : null
}
  
output "transfer_id" {
  description = "The id of the transfer server"
  value       = module.this.enabled ? aws_transfer_server.default.*.id : null
}
