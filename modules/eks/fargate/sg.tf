######################## SECURITY GROUP ########################
#------------------Security Group for EKS Cluster ------------------
resource "aws_security_group" "eks_cluster_sg" {
  name = format("%s-eks-cluster-sg", var.eks_name)
  description = "Security group for EKS cluster"
  vpc_id = var.vpc_id

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
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