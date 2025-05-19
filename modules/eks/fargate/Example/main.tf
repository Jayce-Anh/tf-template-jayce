module "eks" {
  source = "./modules/eks/fargate"
  project = local.project
  vpc_id = local.network.vpc_id
  eks_version = "1.25"
  name = "lab"
  eks_subnet = local.network.private_subnet_id
  fargates = {
    node1 = {
      subnet_ids = local.network.private_subnet_id[0]
      min-size = 1
      max_size = 3
      desired_size = 2
      instance_type = "t3.small"
      disk_size = 10
      disk_type = "gp3"
      taints = {
        node1 = {
          key = "node1"
          value = "node1"
          effect = "NoSchedule"
        }
      }
    }

    node2 = {
      subnet_ids = local.network.private_subnet_id[1]
      min-size = 1
      max_size = 3
      desired_size = 2
      instance_type = "t3.small"
      disk_size = 10
      disk_type = "gp3"
      taints = {
        node2 = {
          key = "node2"
          value = "node2"
          effect = "NoSchedule"
        }
      }
    }
  }

  addons = [
    {
      name = "aws-ebs-csi-driver"
      version = "v1.25.1-eksbuild.1"
    }
  ]
}