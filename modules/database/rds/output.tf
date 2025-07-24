#rds endpoint
output "rds_endpoint" {
  value = aws_db_instance.db.endpoint
}



