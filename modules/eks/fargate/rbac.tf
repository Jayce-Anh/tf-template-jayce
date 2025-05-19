##################################### FARGATE RBAC #########################################
#----------- Provider -----------
provider "kubernetes" {
  host                   = aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.eks.name]
  }
}

#----------- Cluster Auth -----------
data "aws_eks_cluster_auth" "cluster" {
  name = aws_eks_cluster.eks.name
}

#----------- Config Map -----------
# Maps AWS IAM roles to Kubernetes permissions in kube-system namespace

resource "kubernetes_config_map_v1" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode(concat(
      var.map_roles,
      [{
        rolearn  = aws_iam_role.eks_fargate.arn
        username = "system:node:{{SessionName}}"
        groups = [
          "system:bootstrappers",
          "system:nodes",
          "system:node-proxier"
        ]
      }]
    ))
    mapUsers = yamlencode(var.map_users)
  }

  depends_on = [
    aws_eks_cluster.eks
  ]
}