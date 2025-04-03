#------------------ EKS Cluster ------------------
resource "aws_eks_cluster" "eks" {
  name     = var.name
  version  = var.eks_version
  role_arn = aws_iam_role.eks.arn

  vpc_config {
    subnet_ids         = var.eks_subnet_ids
    security_group_ids = var.cluser_security_group_ids
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster,
    aws_iam_role_policy_attachment.eks_vpc,
  ]

  tags = var.project
}

#------------------ EKS Cluster Role ------------------
resource "aws_iam_role" "eks" {
  name = format("%s-eks-role", var.name)

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

resource "aws_iam_role_policy_attachment" "eks_cluster" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks.name
}

resource "aws_iam_role_policy_attachment" "eks_vpc" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks.name
}

#------------------ EKS OpenID Connect Provider ------------------
data "tls_certificate" "eks" {
  url = aws_eks_cluster.eks.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.eks.identity[0].oidc[0].issuer

  tags = var.project
}

#------------------ EKS Addons ------------------
resource "aws_eks_addon" "eks_addons" {
  for_each = { for v in var.addons : v.name => v }

  cluster_name                = aws_eks_cluster.eks.name
  addon_name                  = each.value.name
  addon_version               = each.value.version
  service_account_role_arn    = lookup(each.value, "role_arn", null)
  resolve_conflicts_on_update = each.value.resolve_conflicts_on_update
  resolve_conflicts_on_create = each.value.resolve_conflicts_on_create
  tags                        = var.project
}
