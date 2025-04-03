resource "random_password" "master" {
  length  = 16
  special = false
}

resource "aws_secretsmanager_secret" "password" {
  name                    = "/${var.project.env}/${var.project.name}/${var.secret_name}"
  recovery_window_in_days = 30
}

resource "aws_secretsmanager_secret_version" "password" {
  secret_id     = aws_secretsmanager_secret.password.id
  secret_string = random_password.master.result
}
