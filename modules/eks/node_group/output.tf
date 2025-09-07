############################ OUTPUT ############################
# EKS cluster id
output "eks_cluster_id" {
  value = aws_eks_cluster.eks.id
}

# EKS cluster name
output "eks_cluster_name" {
  value = aws_eks_cluster.eks.name
}
