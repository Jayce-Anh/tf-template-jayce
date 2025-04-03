output "role_arn" {
  value = aws_iam_role.role.arn
}

output "role_name" {
  value = aws_iam_role.role.name
}

output "instance_profile_name" {
  value = try(aws_iam_instance_profile.this[0].name, null)
}
