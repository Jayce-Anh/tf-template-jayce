#################################### EKS CLUSTER ####################################
#------------------ EKS Cluster Security Group ------------------
resource "aws_security_group" "eks_cluster" {
  name = format("%s-eks-cluster-sg", var.name)
  description = "Security group for EKS cluster"
  vpc_id = var.eks_vpc
  
  # Using dynamic blocks for ingress rules
  dynamic "ingress" {
    for_each = lookup(var.cluster_ingress_rules, "ingress_rules", [
      {
        security_groups = [aws_security_group.node_groups.id]
        from_port       = 443
        to_port         = 443
        protocol        = "tcp"
        description     = "Allow worker nodes to communicate with control plane"
      }
    ])

    content {
      self            = lookup(ingress.value, "self", null)
      security_groups = lookup(ingress.value, "security_groups", null)
      from_port       = lookup(ingress.value, "from_port", null)
      to_port         = lookup(ingress.value, "to_port", null)
      protocol        = lookup(ingress.value, "protocol", null)
      cidr_blocks     = lookup(ingress.value, "cidr_blocks", null)
      description     = lookup(ingress.value, "description", null)
    }
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = var.project
}

#------------------ EKS Cluster ------------------
resource "aws_eks_cluster" "eks" {
  name     = var.name
  version  = var.eks_version
  role_arn = aws_iam_role.eks.arn

  vpc_config {
    subnet_ids         = var.eks_subnet
    security_group_ids = [aws_security_group.eks_cluster.id]
  }

  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster,
    aws_iam_role_policy_attachment.eks_vpc,
  ]

  tags = var.project
}

####################### EKS CLUSTER IAM ROLE #######################
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

####################### EKS ADDONS #######################
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

resource "aws_eks_addon" "aws_ebs_csi_driver" {
  cluster_name = aws_eks_cluster.eks.name
  addon_name   = "aws-ebs-csi-driver"
  addon_version = "v1.25.1-eksbuild.1"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"
}

# Extra addons
resource "aws_eks_addon" "eks_addons_extra" {
  for_each = { for v in var.addons : v.name => v }

  cluster_name                = aws_eks_cluster.eks.name
  addon_name                  = each.value.name
  addon_version               = each.value.version
  service_account_role_arn    = lookup(each.value, "role_arn", null)
  resolve_conflicts_on_update = each.value.resolve_conflicts_on_update
  resolve_conflicts_on_create = each.value.resolve_conflicts_on_create
  tags                        = var.project
}

####################### KUBECTL PROVIDER #######################
terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }
}

provider "kubectl" {
  host                   = aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.eks.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.eks.name]
  }
}

####################### EKS OPENID CONNECT PROVIDER #######################
data "tls_certificate" "eks" {
  url = aws_eks_cluster.eks.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.eks.identity[0].oidc[0].issuer

  tags = var.project
}