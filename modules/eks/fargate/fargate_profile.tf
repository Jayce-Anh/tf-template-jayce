#------------------ Fargate Profile ------------------
resource "aws_eks_fargate_profile" "eks_fargate" {
  for_each = var.fargates

  cluster_name           = aws_eks_cluster.eks.name
  fargate_profile_name   = each.key
  pod_execution_role_arn = aws_iam_role.eks_fargate.arn
  subnet_ids             = lookup(each.value, "subnet_ids")

  selector {
    namespace = "default"
  }

  tags = var.project
}

#------------------ Fargate Profile IAM Role ------------------
resource "aws_iam_role" "eks_fargate" {
  name = format("%s-eks-fargate-role", var.name)

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

  tags = var.project
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
