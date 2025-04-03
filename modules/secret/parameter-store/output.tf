output "ssm_name" {
  value = [for param in aws_ssm_parameter.ssm : param.name]  
}
