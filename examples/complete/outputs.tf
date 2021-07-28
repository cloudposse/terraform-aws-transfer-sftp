output "id" {
  description = "ID of the created example"
  value       = module.example.id
}

output "transfer_endpoint" {
  description = "Endpoint for your SFTP connection"
  value = module.example.transfer_endpoint 
}