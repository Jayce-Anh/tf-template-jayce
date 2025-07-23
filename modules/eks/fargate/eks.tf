######################## EKS FARGATE ########################
#------------------ EKS Cluster ------------------
resource "aws_eks_cluster" "eks" {
  name     = var.eks_name
  version  = var.eks_version
  role_arn = aws_iam_role.eks.arn

  vpc_config {
    subnet_ids         = var.eks_subnet
    security_group_ids = [aws_security_group.eks_cluster_sg.id]
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster,
    aws_iam_role_policy_attachment.eks_vpc,
  ]

  tags = merge(var.tags, {
    Name = "${var.project.env}-${var.project.name}-eks-cluster"
  })
}

#------------------ EKS Addons ------------------
resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.eks.name
  addon_name   = "vpc-cni"
  addon_version = "v1.25.1-eksbuild.1"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"
}

resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.eks.name
  addon_name   = "coredns"
  addon_version = "v1.25.1-eksbuild.1"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.eks.name
  addon_name   = "kube-proxy"
  addon_version = "v1.25.1-eksbuild.1"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"
}

# Extra addons
resource "aws_eks_addon" "eks_addons_extra" {
  for_each = { for v in var.addons : v.name => v }

  cluster_name             = aws_eks_cluster.eks.name
  addon_name               = each.value.name
  addon_version            = each.value.version
  service_account_role_arn = lookup(each.value, "role_arn", null)
  
  tags = merge(var.tags, {
    Name = "${var.project.env}-${var.project.name}-eks-addon-${each.value.name}"
  })
}

#------------------ EKS OpenID Connect Provider ------------------
data "tls_certificate" "eks" {
  url = aws_eks_cluster.eks.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.eks.identity[0].oidc[0].issuer

  tags = merge(var.tags, {
    Name = "${var.project.env}-${var.project.name}-eks-oidc-provider"
  })
}