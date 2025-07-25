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

  tags = merge(var.tags, {
    Name = "${var.project.env}-${var.project.name}-eks-fargate-profile-${each.key}"
  })
}

