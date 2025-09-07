locals {
  default_map_roles = [
    {
      groups   = ["system:bootstrappers", "system:nodes"]
      rolearn  = aws_iam_role.node_group.arn
      username = "system:node:{{EC2PrivateDNSName}}"
    }
  ]

  mapRoles = distinct(concat(
    local.default_map_roles,
    var.map_roles,
  ))
}

# Using EKS access entries instead of aws-auth ConfigMap (modern approach)
resource "aws_eks_access_entry" "node_group" {
  cluster_name      = aws_eks_cluster.eks.name
  principal_arn     = aws_iam_role.node_group.arn
  kubernetes_groups = ["system:bootstrappers", "system:nodes"]
  type             = "EC2_LINUX"

  depends_on = [
    aws_eks_cluster.eks,
    aws_eks_node_group.node_groups
  ]
}

# Additional access entries for custom roles
resource "aws_eks_access_entry" "additional_roles" {
  for_each = { for idx, role in var.map_roles : idx => role }

  cluster_name      = aws_eks_cluster.eks.name
  principal_arn     = each.value.rolearn
  kubernetes_groups = each.value.groups
  type             = "STANDARD"

  depends_on = [
    aws_eks_cluster.eks
  ]
}

# Legacy aws-auth ConfigMap (commented out - using access entries instead)
# resource "kubectl_manifest" "aws_auth" {
#   yaml_body = <<YAML
# apiVersion: v1
# kind: ConfigMap
# metadata:
#   labels:
#     app.kubernetes.io/managed-by: terraform
#   name: aws-auth
#   namespace: kube-system
# data:
#   mapAccounts: |
#     []
#   mapRoles: |
#     ${indent(4, yamlencode(local.mapRoles))}
#   mapUsers: |
#     []
# YAML
#
#   depends_on = [
#     aws_eks_cluster.eks,
#     aws_eks_node_group.node_groups
#   ]
# }
