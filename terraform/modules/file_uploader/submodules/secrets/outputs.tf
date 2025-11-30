
output "auth_secret" {
  description = "The API Gateway authentication secret from Secrets Manager"
  value       = local.auth_secret
  sensitive   = true
}

output "secret_arn" {
  description = "The ARN of the secret"
  value       = data.aws_secretsmanager_secret.file_upload_secrets.arn
}