#-------------------------------------VPC-------------------------------------#
module "vpc" {
  source     = "./modules/vpc"
  project    = local.project
  cidr_block = "10.0.0.0/16"
  subnet_az = {
    "ap-southeast-1a" = 1
    "ap-southeast-1c" = 2
  }
}

#-------------------------------------Ec2 instance-------------------------------------#
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
  path_user_data             = "${path.module}/scripts/user_data.sh"
}

#-------------------------------------Target Group-------------------------------------#
module "tg-1" {
  source            = "./modules/tg"
  project           = local.project
  tg_name           = "tg-1"
  service_port      = 80
  lb_listener_arn   = module.external_lb.lb_listener_arn
  vpc_id            = local.network.vpc_id
  health_check_path = "/health"
  ec2_id            = module.ec2_instance.ec2_id
  priority          = 1
  host_header       = "1.jaeger-terraform.lab"
}

module "tg-2" {
  source            = "./modules/tg"
  project           = local.project
  tg_name           = "tg-2"
  service_port      = 81
  lb_listener_arn   = module.external_lb.lb_listener_arn
  vpc_id            = local.network.vpc_id
  health_check_path = "/health"
  ec2_id            = module.ec2_instance.ec2_id
  priority          = 2
  host_header       = "2.jaeger-terraform.lab"
}

#-------------------------------------External Load Balancer-------------------------------------#
module "external_lb" {
  source                 = "./modules/alb/external"
  project                = local.project
  lb_name                = "ex-alb"
  vpc_id                 = local.network.vpc_id
  dns_cert_arn           = module.acm.cert_arn
  subnet_ids             = local.network.public_subnet_id
  source_ingress_sg_cidr = ["0.0.0.0/0"]
}

#-------------------------------------ACM-------------------------------------#
module "acm" {
  source = "./modules/acm"
  project = local.project
  domain = "jaeger-terraform.lab"
}

#-------------------------------------EKS-------------------------------------#
module "eks" {
  source = "./modules/eks"
  project = local.project

  name = "tf-mod-test"

  eks_version    = "1.25"
  eks_vpc_id     = local.network.vpc_id
  eks_subnet_ids = local.network.public_subnet_id
  node_groups = {
    mng1 = {
      subnet_ids                  = local.network.public_subnet_id[0]
      min-size                    = 1
      max_size                    = 3
      desired_size                = 1
      instance_type               = "t3.medium"
      disk_size                   = 50
      disk_type                   = "gp3"
      associate_public_ip_address = true
      block_device_mappings = [
        {
          device_name = "/dev/xvdb"
          disk_size   = 50
          disk_type   = "gp3"
          mount_path  = "/var/kend"
          snapshot_id = data.aws_ebs_snapshot.this.id
        },
        {
          device_name = "/dev/xvdc"
          disk_size   = 50
          disk_type   = "gp3"
          mount_path  = "/var/test"
        },
      ]
    }
    mng2 = {
      subnet_ids                  = local.network.public_subnet_id[1]
      min-size                    = 1
      max_size                    = 3
      desired_size                = 1
      instance_type               = "t3.small"
      disk_size                   = 10
      disk_type                   = "gp2"
      associate_public_ip_address = true
      security_group_ids          = [module.eks.eks_cluster.security_group_id]
      ingress_rules = [
        { self = true, protocol = "tcp", from_port = 80, to_port = 80 },
      ]
    }
  }
  map_roles = [
    {
      rolearn  = "arn:aws:iam::428948643293:role/klaytn-devops"
      username = "administrator"
      groups   = ["system:masters"]
    }
  ]
  extra_iam_policies = [
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
  ]

  addons = [
    {
      name                        = "aws-ebs-csi-driver"
      version                     = "v1.10.0-eksbuild.1"
      resolve_conflicts_on_update = "OVERWRITE"
    }
  ]
}

#-------------------------------------CICD-------------------------------------#
#Pipeline BE
module "code_pipeline_be" {
  source = "./modules/cicd/code_pipeline"
  project = local.project
  pipeline_name          = "lab-terraform"
  project_name           = module.code_build.project_name
  # application_name       = "${local.project.env}-${local.project.project}-api"
  # deployment_group_name  = "${local.project.env}-${local.project.project}-api" 
  git_branch             = "main"
  git_repo               = "test-jaeger-terraform"
  organization           = "sotatek"
  oauth_token            = var.oauth_token
}

module "code_build_be" {
  source = "./modules/cicd/code_build"
  project = local.project
  codebuild_role_arn = module.code_pipeline.codebuild_role_arn
  env_vars_codebuild = {
    REGISTRY_URL    = module.ecr_be.repo_url
    SERVICE         = "${local.project.env}-${local.project.name}-be"
    REGION          = local.project.region
    PARAMETER_STORE = "/${local.project.env}/${local.project.name}/be/env"
    CONTAINER_NAME  = "${local.project.name}-be"
  }
  buildspec_file = file("${path.module}/cicd/pipeline/be-buildspec.yml")
}

#Pipeline FE
module "code_pipeline_fe" {
  source = "./modules/cicd/code_pipeline"
  project = local.project
  pipeline_name          = "lab-terraform"
  project_name           = module.code_build.project_name
  git_branch             = "main"
  git_repo               = "test-jaeger-terraform"
  organization           = "sotatek"
  oauth_token            = var.oauth_token
}

module "code_build_fe" {
  source = "./modules/cicd/code_build"
  project = local.project
  codebuild_role_arn = module.code_pipeline.codebuild_role_arn
  env_vars_codebuild = {
    REGISTRY_URL    = module.ecr_fe.repo_url
    SERVICE         = "${local.project.env}-${local.project.name}-fe"
    REGION          = local.project.region
    PARAMETER_STORE = "/${local.project.env}/${local.project.name}/fe/env"
    CONTAINER_NAME  = "${local.project.name}-fe"
  }
  buildspec_file = file("${path.module}/cicd/pipeline/fe-buildspec.yml")
}

#-------------------------------- ECR -------------------------------------#
module "ecr_be" {
  source = "./modules/ecr"
  project = local.project
  source_services = ["be"]
}

module "ecr_fe" {
  source = "./modules/ecr"
  project = local.project
  source_services = ["fe"]
}

#-------------------------------------SNS-------------------------------------#
module "sns_alarm" {
  source      = "./modules/sns"
  project     = local.project
  URL_GG_HOOK = "https://chat.googleapis.com/v1/spaces/AAAA6ublkJQ/messages?key=AIzaSyDdI0hCZtE6vySjMm-WEfRq3CPzqKqqsHI&token=MJ5QNtA8EPTF7SicSlrdU1FBoIbB9HbsCtUP_TNqXT4"
}





