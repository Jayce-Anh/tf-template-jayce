######################## ALB ########################
output "lb_arn" {
  value = aws_lb.lb.arn
}

output "lb_sg_id" {
  value = aws_security_group.sg_lb.id
}

output "lb_listener_http_arn" {
  value = aws_lb_listener.lb_listener_http.arn
}

output "lb_listener_https_arn" {
  value = var.dns_cert_arn != null ? aws_lb_listener.lb_listener_https[0].arn : null
}

######################## TARGET GROUP ########################
output "tg_arns" {
  value = { for k, v in aws_lb_target_group.tg : k => v.arn }
}