resource "aws_ecr_repository" "ecr" {
  for_each     = var.source_services
  name         = "${var.project.env}-${var.project.name}-${each.key}"
  force_delete = var.s3_force_del
  
  tags = merge(var.tags, {
    Name = "${var.project.env}-${var.project.name}-${each.key}"
  })
}