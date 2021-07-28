output "id" {
  description = "ID of the created example"
  value       = module.this.enabled ? module.this.id : null
}

output "transfer_endpoint" {
  description = "The endpoint of the Transfer Server"
  value       = aws_transfer_server.default.endpoint
}
