######################## SECURITY GROUP ########################
#------------------Security Group for EKS Cluster ------------------
resource "aws_security_group" "eks_cluster_sg" {
  name = format("%s-eks-cluster-sg", var.eks_name)
  description = "Security group for EKS cluster"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "Allow HTTPS communication from VPC"
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project.env}-${var.project.name}-${var.eks_name}-eks-cluster-sg"
  })
}

# Allow cluster to communicate with Fargate pods
resource "aws_security_group_rule" "cluster_to_fargate" {
  security_group_id        = aws_security_group.eks_cluster_sg.id
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_fargate_node_group_sg.id
  description              = "Allow Fargate pods to communicate with cluster"
}

################### Security Group for EKS Fargate Node Group ########################
resource "aws_security_group" "eks_fargate_node_group_sg" {
  name = format("%s-eks-fargate-node-group-sg", var.eks_name)
  description = "Security group for EKS fargate node group"
  vpc_id = var.vpc_id

  ingress {
    from_port                = 443
    to_port                  = 443
    protocol                 = "tcp"
    security_groups          = [aws_security_group.eks_cluster_sg.id]
    description              = "Allow communication from EKS cluster"
  }

  ingress {
    from_port = 1025
    to_port = 65535
    protocol = "tcp"
    self = true
    description = "Allow node-to-node communication"
  }

  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "Allow DNS resolution from VPC"
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project.env}-${var.project.name}-${var.eks_name}-fargate-sg"
  })
}

#extra ingress rules
resource "aws_security_group_rule" "eks_fargate_node_group_sg_ingress_extra" {
  for_each = { for v in var.fargate_sg_ingress : v.name => v }

  security_group_id = aws_security_group.eks_fargate_node_group_sg.id
  type = "ingress"
  from_port = each.value.from_port
  to_port = each.value.to_port
  protocol = each.value.protocol
  cidr_blocks = each.value.cidr_blocks
  description = each.value.description
}