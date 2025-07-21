########################### TARGET GROUPS #####################################
#---------------------------- Target Groups ----------------------------
resource "aws_lb_target_group" "tg" {
  for_each = var.target_groups
  
  name        = "${var.project.env}-${var.project.name}-${each.value.name}"
  port        = each.value.service_port
  protocol    = "HTTP"
  target_type = each.value.target_type
  vpc_id      = var.vpc_id
  deregistration_delay = "60"

  health_check {
    interval            = 30
    path                = each.value.health_check_path
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 5
    matcher             = "200-499"
  }

  tags = merge(var.tags, {
    Name = "${var.project.env}-${var.project.name}-tg-${each.value.name}"
  })
}

#-------------------- Listener Rule of Load Balancer ---------------------
resource "aws_lb_listener_rule" "lb_listener_rule" {
  for_each = var.dns_cert_arn != null ? var.target_groups : {}
  
  listener_arn = aws_lb_listener.lb_listener_https[0].arn
  priority     = each.value.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg[each.key].arn
  }

  condition {
    host_header {
      values = [each.value.host_header]
    }
  }
}

#Register target group target to instance
resource "aws_lb_target_group_attachment" "instance_target_group_attachment" {
  for_each = {
    for k, v in var.target_groups : k => v
    if v.target_type == "instance"
  }
  
  target_group_arn = aws_lb_target_group.tg[each.key].arn
  target_id        = each.value.ec2_id
  port             = each.value.service_port
}




