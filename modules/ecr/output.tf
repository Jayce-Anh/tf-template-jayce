output "repo_url" {
  value = aws_ecr_repository.ecr[tolist(var.source_services)[0]].repository_url
}
