output "id" {
  description = "The ID of the AWS Transfer Server instance"
  value       = module.sftp.id
}

output "transfer_endpoint" {
  description = "The endpoint URL of the AWS Transfer Server for SFTP connections"
  value       = module.sftp.transfer_endpoint
}
