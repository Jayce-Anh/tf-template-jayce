output "ecr_url" {
  value = aws_ecr_repository.ecr[tolist(var.source_services)[0]].repository_url
}

output "ecr_name" {
  value = aws_ecr_repository.ecr[tolist(var.source_services)[0]].name
}