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

#------------------ EBS CSI Driver IAM Role ------------------
resource "aws_iam_role" "ebs_csi_driver" {
  name = format("%s-ebs-csi-driver-role", var.eks_name)

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub": "system:serviceaccount:kube-system:ebs-csi-controller-sa"
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud": "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project.env}-${var.project.name}-${var.eks_name}-ebs-csi-driver-role"
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

#Attach EBS CSI Driver Policy
resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_driver.name
}



