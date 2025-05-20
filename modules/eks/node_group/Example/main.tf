module "eks" {
  source = "./modules/eks/node_group"
  project = local.project
  name = "lab"
  eks_version = "1.25"
  eks_subnet = local.network.private_subnet_id
  eks_vpc = local.network.vpc_id
  cluster_ingress = {
    ingress_rules = {
      rule1 = {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["10.0.0.0/16"]
        description = "Test dynamic rules"
      }
    }
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
      ingress_rules = {
        ssh = {
          from_port   = 22
          to_port     = 22
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
          description = "Allow SSH from VPC for node1"
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
      ingress_rules = {
        ssh = {
          from_port   = 22
          to_port     = 22
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
          description = "Allow SSH from VPC for node2"
        },
        alb = {
          from_port              = 8080
          to_port                = 8080
          protocol               = "tcp"
          source_security_group_id = module.external_lb.lb_sg_id
          description            = "Allow traffic from ALB to node2 on port 8080"
        }
      }
    }
  }
  # addons = [
  #   {
  #     name = "aws-ebs-csi-driver"
  #     version = "v1.25.1-eksbuild.1"
  #   }
  # ]
}