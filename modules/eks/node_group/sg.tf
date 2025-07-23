######################## SECURITY GROUP ########################
#------------------ EKS Cluster Security Group ------------------
resource "aws_security_group" "eks_cluster" {
  name = format("%s-eks-cluster-sg", var.eks_name)
  description = "Security group for EKS cluster"
  vpc_id = var.eks_vpc

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.project, {
    Name = "${var.project.env}-${var.project.name}-eks-cluster-sg"
  })
}

# Allow node groups to communicate with the cluster
resource "aws_security_group_rule" "eks_sg_ingress_from_nodes" {
  for_each = var.node_groups
  
  security_group_id        = aws_security_group.eks_cluster.id
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.node_groups[each.key].id
  description              = "Allow pods to communicate with the cluster API Server"
}

# Extra ingress rules
resource "aws_security_group_rule" "eks_sg_ingress_extra" {
  for_each = try(var.eks_sg_ingress.ingress_rules, {})
  
  security_group_id = aws_security_group.eks_cluster.id
  type              = "ingress"
  self              = lookup(each.value, "self", null)
  source_security_group_id = lookup(each.value, "source_security_group_id", null)
  from_port         = lookup(each.value, "from_port", null)
  to_port           = lookup(each.value, "to_port", null)
  protocol          = lookup(each.value, "protocol", null)
  cidr_blocks       = lookup(each.value, "cidr_blocks", null)
  description       = lookup(each.value, "description", null)
}

#-------------------------- Node Group Security Group --------------------------
resource "aws_security_group" "node_groups" {
  for_each = var.node_groups

  name   = format("%s-%s-eks-node-group-sg", var.eks_name, each.key)
  vpc_id = var.eks_vpc

  ingress {
    from_port                = 443
    to_port                  = 443
    protocol                 = "tcp"
    security_groups          = [aws_security_group.eks_cluster.id] 
    description              = "Allow communication to cluster"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.project, {
    Name = "${var.project.env}-${var.project.name}-eks-node-group-sg"
  })
}

resource "aws_security_group_rule" "node_group_ingress" {
  for_each = {
    for rule_key, rule_value in flatten([
      for ng_key, ng_value in var.node_groups : [
        for rule_key, rule_value in lookup(ng_value, "ingress_rules", {}) : {
          node_group = ng_key
          rule_key   = rule_key
          rule_value = rule_value
        }
      ]
    ]) : "${rule_value.node_group}-${rule_value.rule_key}" => rule_value
  }

  security_group_id        = aws_security_group.node_groups[each.value.node_group].id
  type                     = "ingress"
  self                     = lookup(each.value.rule_value, "self", null)
  source_security_group_id = lookup(each.value.rule_value, "source_security_group_id", null)
  from_port                = lookup(each.value.rule_value, "from_port", null)
  to_port                  = lookup(each.value.rule_value, "to_port", null)
  protocol                 = lookup(each.value.rule_value, "protocol", null)
  cidr_blocks              = lookup(each.value.rule_value, "cidr_blocks", null)
  description              = lookup(each.value.rule_value, "description", null)
}
