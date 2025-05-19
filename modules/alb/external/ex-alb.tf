#-------------------------------------Load Balancer Security Group-------------------------------------#
resource "aws_security_group" "sg_lb" {
  name        = "${var.project.env}-${var.project.name}-sg-${var.lb_name}"
  description = "SG of ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    description = "Allow HTTP from internet"
    cidr_blocks = var.source_ingress_sg_cidr
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#-------------------------------------Application Load Balancer-------------------------------------#
resource "aws_lb" "lb" {
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_lb.id]
  subnets            = var.subnet_ids
  tags = {
    Name = "${var.project.env}-${var.project.name}-${var.lb_name}"
    Description = "External ALB of ${var.project.env}-${var.project.name}"
  }
}

#Listener of Load Balancer
resource "aws_lb_listener" "lb_listener_https" {
  load_balancer_arn = aws_lb.lb.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = var.dns_cert_arn

  default_action {
    type = "fixed-response"
    fixed_response {
      status_code  = "404"
      content_type = "text/plain"
    }
  }
}

resource "aws_lb_listener" "lb_listener_http" {
  load_balancer_arn = aws_lb.lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      status_code  = "404"
      content_type = "text/plain"
    }
  }
}

#----------------------------Target Groups---------------------------------
resource "aws_lb_target_group" "tg" {
  for_each = var.target_groups
  
  name        = "${var.project.env}-${var.project.name}-tg-${each.value.name}"
  port        = each.value.service_port
  protocol    = "HTTP"
  target_type = "instance" # or "ip"
  vpc_id      = var.vpc_id
  deregistration_delay = "60"

  health_check {
    interval            = 10
    path                = each.value.health_check_path
    port                = each.value.service_port
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

#Listener Rule of Load Balancer
resource "aws_lb_listener_rule" "lb_listener_rule" {
  for_each = var.target_groups
  
  listener_arn = aws_lb_listener.lb_listener_http.arn
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
  for_each = var.target_groups
  
  target_group_arn = aws_lb_target_group.tg[each.key].arn
  target_id        = each.value.ec2_id
  port             = each.value.service_port
}

#Register target group target to container
# resource "aws_lb_target_group_attachment" "container_target_group_attachment" {
#   target_group_arn = aws_lb_target_group.tg.arn
#   target_id        = var.container_id
#   port             = var.service_port
# }
#   health_check {
#     interval            = 10
#     path                = each.value.health_check_path
#     port                = each.value.service_port
#     timeout             = 5
#     healthy_threshold   = 2
#     unhealthy_threshold = 2
#     matcher             = "200"
#   }
# }

