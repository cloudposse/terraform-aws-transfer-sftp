output "id" {
  description = "The null label ID passed to each resource"
  value       = module.sftp.id
}

output "transfer_endpoint" {
  description = "Endpoint for your SFTP connection"
  value       = module.sftp.transfer_endpoint
}
