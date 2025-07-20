############################### SECRET MANAGER - OUTPUT ###############################

output "secret_name" {
  description = "Name of the secret-manager"
  value = aws_secretsmanager_secret.secret.name
}

output "secret_arn" {
  description = "ARN of the secret-manager"
  value       = aws_secretsmanager_secret.secret.arn
}


