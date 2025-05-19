############################### VPC #######################################
module "vpc" {
  source     = "./modules/vpc"
  project    = local.project
  cidr_block = "10.0.0.0/16"
  subnet_az = {
    "ap-southeast-1a" = 1
    "ap-southeast-1c" = 2
  }
}

################################ Ec2 instance #######################################
module "ec2_instance" {
  source                     = "./modules/ec2"
  project                    = local.project
  network                    = local.network
  enabled_eip                = true
  instance_type              = "t3.micro"
  instance_name              = "ec2"
  key_name                   = "lab-jaeger-terraform"
  iops                       = 3000
  volume_size                = 30
  source_ingress_ec2_sg_cidr = ["0.0.0.0/0"]
  subnet_id                  = local.network.public_subnet_id[0]
  alb_sg_id                  = module.external_lb.lb_sg_id
}

################################ External Load Balancer #######################################
module "external_lb" {
  source                 = "./modules/alb/external"
  project                = local.project
  lb_name                = "ex-alb"
  vpc_id                 = local.network.vpc_id
  dns_cert_arn           = module.acm.cert_arn
  subnet_ids             = local.network.public_subnet_id
  source_ingress_sg_cidr = ["0.0.0.0/0"]

  target_groups = {
    tg1 = {
      name             = "tg-1"
      service_port     = 80
      health_check_path = "/health"
      priority         = 1
      host_header      = "1.jaeger-terraform.lab"
      ec2_id           = module.ec2_instance.ec2_id
    },
    tg2 = {
      name             = "tg-2"
      service_port     = 81
      health_check_path = "/health"
      priority         = 2
      host_header      = "2.jaeger-terraform.lab"
      ec2_id           = module.ec2_instance.ec2_id
    }
  }
}

################################ ACM #######################################
module "acm" {
  source = "./modules/acm"
  project = local.project
  domain = "jaeger-terraform.lab"
}

################################ EKS #######################################
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
        description = "Test dynamic rules"
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
        description = "Test dynamic rules"
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
    }
    node2 = {
      subnet_ids = local.network.private_subnet_id[1]
      min_size = 1
      max_size = 3
      desired_size = 2
      instance_type = "t3.small"
      disk_size = 10
      disk_type = "gp3"
    }
  }
}
  
# ################################ CICD #######################################
# #Pipeline BE
# module "code_pipeline_be" {
#   source = "./modules/cicd/code_pipeline"
#   project = local.project
#   pipeline_name          = "lab-terraform"
#   project_name           = module.code_build_be.project_name
#   # application_name       = "${local.project.env}-${local.project.project}-api"
#   # deployment_group_name  = "${local.project.env}-${local.project.project}-api" 
#   git_branch             = "main"
#   git_repo               = "test-jaeger-terraform"
#   git_org                = "sotatek"
#   git_token            = var.git_token
# }

# module "code_build_be" {
#   source = "./modules/cicd/code_build"
#   project = local.project
#   codebuild_role_arn = module.code_pipeline_be.codebuild_role_arn
#   env_vars_codebuild = {
#     REGISTRY_URL    = module.ecr_be.repo_url
#     SERVICE         = "${local.project.env}-${local.project.name}-be"
#     REGION          = local.project.region
#     PARAMETER_STORE = "/${local.project.env}/${local.project.name}/be/env"
#     CONTAINER_NAME  = "${local.project.name}-be"
#   }
#   buildspec_file = file("${path.module}/cicd/pipeline/be-buildspec.yml")
# }

# #Pipeline FE
# module "code_pipeline_fe" {
#   source = "./modules/cicd/code_pipeline"
#   project = local.project
#   pipeline_name          = "lab-terraform"
#   project_name           = module.code_build_fe.project_name
#   git_branch             = "main"
#   git_repo               = "test-jaeger-terraform"
#   git_org                = "sotatek"
#   git_token              = var.git_token
# }

# module "code_build_fe" {
#   source = "./modules/cicd/code_build"
#   project = local.project
#   codebuild_role_arn = module.code_pipeline_fe.codebuild_role_arn
#   env_vars_codebuild = {
#     REGISTRY_URL    = module.ecr_fe.repo_url
#     SERVICE         = "${local.project.env}-${local.project.name}-fe"
#     REGION          = local.project.region
#     PARAMETER_STORE = "/${local.project.env}/${local.project.name}/fe/env"
#     CONTAINER_NAME  = "${local.project.name}-fe"
#   }
#   buildspec_file = file("${path.module}/cicd/pipeline/fe-buildspec.yml")
# }

################################ ECR #######################################
module "ecr" {
  source = "./modules/ecr"
  project = local.project
  source_services = ["be", "fe"]
}

################################ SNS #######################################
module "sns_alarm" {
  source      = "./modules/sns"
  project     = local.project
  URL_GG_HOOK = "https://chat.googleapis.com/v1/spaces/AAAA6ublkJQ/messages?key=AIzaSyDdI0hCZtE6vySjMm-WEfRq3CPzqKqqsHI&token=MJ5QNtA8EPTF7SicSlrdU1FBoIbB9HbsCtUP_TNqXT4"
}





