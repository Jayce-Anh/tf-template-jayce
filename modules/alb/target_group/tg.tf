#----------------------------Target Group---------------------------------
resource "aws_lb_target_group" "tg" {
  name        = "${var.project.env}-${var.project.name}-tg-${var.tg_name}"
  port        = var.service_port
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.vpc_id
  deregistration_delay = "60"

  health_check {
    interval            = 10
    path                = var.health_check_path
    port                = var.service_port
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

#Listener Rule of Load Balancer
resource "aws_lb_listener_rule" "lb_listener_rule" {
  listener_arn = var.lb_listener_arn
  priority     = var.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }

  condition {
    host_header {
      values = [var.host_header]
    }
  }
}

#Register target group target to instance
resource "aws_lb_target_group_attachment" "instance_target_group_attachment" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = var.ec2_id
  port             = var.service_port
}

#Register target group target to container
# resource "aws_lb_target_group_attachment" "container_target_group_attachment" {
#   target_group_arn = aws_lb_target_group.tg.arn
#   target_id        = var.container_id
#   port             = var.service_port
# }