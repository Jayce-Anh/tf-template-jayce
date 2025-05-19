module "eks" {
  source = "./modules/eks/node_group"
  project = local.project
  name = "lab"
  eks_version = "1.25"
  eks_subnet = local.network.private_subnet_id
  eks_vpc = local.network.vpc_id
  cluster_ingress_rules = {
    ingress_rules = [
      {
        cidr_blocks = ["10.0.0.0/20"]
        from_port = 443
        to_port = 443
        protocol = "tcp"
        description = "Example dynamic rules"
      }
    ]
  }
  node_group_ingress_rules = {
    ingress_rules = [
      {
        cidr_blocks = ["10.0.0.0/16"]
        from_port = 443
        to_port = 443
        protocol = "tcp"
        description = "Example dynamic rules"
      }
    ]
  }
  node_groups = {
    node1 = {
      subnet_ids = local.network.private_subnet_id[0]
      min_size = 1
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
      min_size = 1
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
  addons = {
    "aws-ebs-csi-driver" = {
      addon_name = "aws-ebs-csi-driver"
      addon_version = "v1.21.0-eksbuild.1"
    }
  }
}