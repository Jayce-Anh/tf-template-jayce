resource "aws_ecr_repository" "ecr" {
  for_each = var.source_services
  name     = "${var.project.env}-${var.project.name}-${each.key}"
}