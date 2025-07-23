######################## EKS FARGATE IAM ROLE ########################
#------------------ EKS Cluster IAM Role ------------------
resource "aws_iam_role" "eks" {
  name = format("%s-eks-role", var.eks_name)

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.project
}

#Attach EKS Cluster Policy
resource "aws_iam_role_policy_attachment" "eks_cluster" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks.name
}

#Attach EKS VPC Resource Controller Policy
resource "aws_iam_role_policy_attachment" "eks_vpc" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks.name
}

#------------------ Fargate Profile IAM Role ------------------
resource "aws_iam_role" "eks_fargate" {
  name = format("%s-eks-fargate-role", var.eks_name)

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks-fargate-pods.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })

  tags = merge(var.tags, {
    Name = "${var.project.env}-${var.project.name}-${var.eks_name}-eks-fargate-role"
  })
}

#Attach Fargate Pod Execution Role Policy
resource "aws_iam_role_policy_attachment" "eks_fargate_common" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.eks_fargate.name
}

#Attach Extra IAM Policies
resource "aws_iam_role_policy_attachment" "eks_fargate_extra" {
  for_each = { for v in var.extra_iam_policies : v => v }

  policy_arn = each.value
  role       = aws_iam_role.eks_fargate.name
}