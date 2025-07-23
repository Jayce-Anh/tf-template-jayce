####################### SECURITY GROUP #######################
resource "aws_security_group" "ec2-sg" {
  vpc_id      = var.network.vpc_id
  description = "${var.project.env}-${var.project.name}-${var.instance_name}-sg"
  name        = "${var.project.env}-${var.project.name}-${var.instance_name}-sg"
}

#Security Group Rule for ALB-based ingress (when ALB security group is provided)
resource "aws_security_group_rule" "ingress-alb-rule" {
  for_each = var.alb_sg_id != null ? var.sg_ingress : {}

  security_group_id        = aws_security_group.ec2-sg.id
  type                     = "ingress"
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  protocol                 = each.value.protocol
  description              = each.value.description
  source_security_group_id = var.alb_sg_id
}

#Security Group Rule for CIDR-based ingress (when no ALB security group is provided)
resource "aws_security_group_rule" "ingress-cidr-rule" {
  for_each = var.alb_sg_id == null ? var.sg_ingress : {}

  security_group_id = aws_security_group.ec2-sg.id
  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  description       = each.value.description
  cidr_blocks       = var.source_ingress_ec2_sg_cidr
}

resource "aws_security_group_rule" "egress-rule" {
  security_group_id = aws_security_group.ec2-sg.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}