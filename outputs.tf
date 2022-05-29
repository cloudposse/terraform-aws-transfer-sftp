output "id" {
  description = "ID of the created example"
  value       = module.this.enabled ? module.this.id : null
}

output "transfer_endpoint" {
  description = "The endpoint of the Transfer Server"
  value       = module.this.enabled ? join("", aws_transfer_server.default.*.endpoint) : null
}
output "transfer_vpc_endpoint_details" {
  description = "Transfer server VPC endpoint details"
  value       = module.this.enabled && local.is_vpc ? join("", aws_transfer_server.default.*.endpoint_details) : null
}

output "elastic_ips" {
  description = "Provisioned Elastic IP IDs"
  value       = module.this.enabled && var.eip_enabled ? aws_eip.sftp.*.id : null
}

output "elastic_ip_private_ips" {
  description = "Provisioned Elastic IP private addresses"
  value       = module.this.enabled && var.eip_enabled ? aws_eip.sftp.*.private_ip : null
}
output "elastic_ip_public_ips" {
  description = "Provisioned Elastic IP public addresses"
  value       = module.this.enabled && var.eip_enabled ? aws_eip.sftp.*.public_ip : null
}

output "transfer_id" {
  description = "The id of the transfer server"
  value       = module.this.enabled ? join("", aws_transfer_server.default.*.id) : null
}
