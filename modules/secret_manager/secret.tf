################################# SECRET MANAGER #################################

#Create secret
resource "aws_secretsmanager_secret" "secret" {
  name                    = var.secret_name
  recovery_window_in_days = var.recovery_window_in_days
  
  tags = merge(var.tags, {
    Name = "${var.project.env}-${var.project.name}-${var.secret_name}"
  })
}

#Create secret version
resource "aws_secretsmanager_secret_version" "secret" {
  secret_id     = aws_secretsmanager_secret.secret.id
  secret_string = "init"
  lifecycle {
    ignore_changes = [ secret_string ]
  }
}