######################## EKS SECURITY GROUPS ########################
# Proper EKS security group configuration following AWS best practices

# Note: EKS automatically creates a cluster security group with proper rules
# No need to create a custom cluster SG - it's redundant and can cause conflicts

#-------------------------- Node Group Security Group --------------------------
resource "aws_security_group" "node_groups" {
  for_each = var.node_groups

  name_prefix = "${var.eks_name}-${each.key}-node-sg-"
  description = "Security group for EKS node group ${each.key}"
  vpc_id      = var.eks_vpc

  # Outbound: To cluster control plane and internet (via NAT Gateway)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic (for pulling images, updates, etc.)"
  }

  # Dynamic ingress rules from node group configuration
  dynamic "ingress" {
    for_each = lookup(each.value, "ingress_rules", {})
    iterator = rule

    content {
      from_port       = rule.value.from_port
      to_port         = rule.value.to_port
      protocol        = rule.value.protocol
      cidr_blocks     = lookup(rule.value, "cidr_blocks", null)
      security_groups = lookup(rule.value, "source_security_group_id", null) != null ? [rule.value.source_security_group_id] : null
      self           = lookup(rule.value, "self", null)
      description    = lookup(rule.value, "description", null)
    }
  }

  tags = merge(var.tags, {
    Name = "${var.project.env}-${var.project.name}-${each.key}-node-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}