output "sg_ecs_task" {
  value = aws_security_group.sg_ecs_task.id
}

output "role_auto_scaling" {
  value = aws_iam_role.role_auto_scaling.arn
}

output "role_execution" {
  value = aws_iam_role.role_execution.arn
}

output "role_ecs_service" {
  value = aws_iam_role.role_ecs_service.arn
}

output "ecs_cluster_id" {
  value = aws_ecs_cluster.ecs_cluster.id
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.ecs_cluster.name
}

output "ecs_cluster_arn" {
  value = aws_ecs_cluster.ecs_cluster.arn
}
