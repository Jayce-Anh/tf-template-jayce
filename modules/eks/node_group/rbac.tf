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

resource "kubectl_manifest" "aws_auth" {
  yaml_body = <<YAML
apiVersion: v1
kind: ConfigMap
metadata:
  labels:
    app.kubernetes.io/managed-by: terraform
  name: aws-auth
  namespace: kube-system
data:
  mapAccounts: |
    []
  mapRoles: |
    ${indent(4, yamlencode(local.mapRoles))}
  mapUsers: |
    []
YAML

  depends_on = [
    aws_eks_cluster.eks
  ]
}
