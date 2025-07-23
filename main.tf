############################ VPC ############################
module "vpc" {
  source     = "./modules/vpc"
  project    = local.project
  tags       = local.tags
  cidr_block = "10.0.0.0/16"
  subnet_az = {
    "ap-southeast-1a" = 1
    "ap-southeast-1b" = 2
  }
}

############################ BASTION ############################
module "bastion" {
  source                     = "./modules/ec2"
  project                    = local.project
  tags                       = local.tags
  network                    = local.network
  enabled_eip                = true
  instance_type              = "t3a.small"
  instance_name              = "bastion"
  iops                       = 3000
  volume_size                = 30
  source_ingress_ec2_sg_cidr = ["0.0.0.0/0"]
  path_user_data             = "${path.root}/scripts/user_data/user_data.sh"
  key_name                   = "lab-jayce"
  subnet_id                  = local.network.public_subnet_ids[0] #use public subnet 

  sg_ingress = {
    rule1 = {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "Connect to bastion"
    }
  }
}

############################ EXTERNAL LB ############################
module "alb" {
  source                 = "./modules/alb/external"
  project                = local.project
  tags                   = local.tags
  lb_name                = "ex-alb"
  vpc_id                 = local.network.vpc_id
  dns_cert_arn           = module.acm_alb.cert_arn
  subnet_ids             = local.network.public_subnet_ids
  source_ingress_sg_cidr = ["0.0.0.0/0"]

  target_groups = {
    be = {
      name              = "be"
      service_port      = 5000
      health_check_path = "/health"
      priority          = 1
      host_header       = "todo-be.jayce-lab.work"
      target_type       = "ip"
      ec2_id            = null
    }
  }
}

############################ ACM ############################
#Certificate for ALB
module "acm_alb" {
  source  = "./modules/acm"
  project = local.project
  tags    = local.tags
  domain  = "*.jayce-lab.work"
  region  = local.project.region
}

#Certificate for CloudFront
module "acm_s3cf" {
  source  = "./modules/acm"
  project = local.project
  tags    = local.tags
  domain  = "*.jayce-lab.work"
  region  = "us-east-1"
}

########################### CLOUDFRONT ############################
module "cloudfront" {
  source            = "./modules/cloudfront"
  project           = local.project
  tags              = local.tags
  service_name      = "todo-fe"
  cf_cert_arn       = module.acm_s3cf.cert_arn
  s3_force_del      = true
  cloudfront_domain = "todo-fe.jayce-lab.work"
  custom_error_response = {
    "403" = {
      error_code         = 403
      response_code      = 200
      response_page_path = "/index.html"
    }
    "404" = {
      error_code         = 404
      response_code      = 200
      response_page_path = "/index.html"
    }
  }
}

############################# ECR ###################################
module "ecr" {
  source          = "./modules/ecr"
  project         = local.project
  tags            = local.tags
  s3_force_del    = true
  source_services = ["be"]
}

############################# RDS #################################
module "rds" {
  source  = "./modules/rds"
  project = local.project
  network = local.network
  tags    = local.tags

  rds_name = "mysql-db"
  db_name  = local.project.name
  multi_az = false
  allowed_sg_ids_access_rds = [
    module.bastion.ec2_sg_id,
    module.ecs.ecs_tasks_sg_id,
  ]

  rds_storage_type = "gp3"
  rds_iops         = 3000
  rds_throughput   = 125

  rds_storage     = 30
  rds_max_storage = 100

  rds_username = var.rds_username
  rds_password = var.rds_password

  rds_class                             = "db.t4g.small"
  rds_engine                            = "mysql"
  rds_engine_version                    = "8.0"
  rds_port                              = 3306
  rds_backup_retention_period           = 7
  performance_insights_retention_period = 0

  rds_family = "mysql8.0"
  aws_db_parameters = {
    "max_connections"          = 500
    "require_secure_transport" = 0
  }
}

############################ REDIS #################################
module "redis" {
  source                           = "./modules/redis"
  project                          = local.project
  network                          = local.network
  tags                             = local.tags
  redis_name                       = "redis"
  redis_engine                     = "redis"
  redis_engine_version             = "6.2"
  redis_port                       = 6379
  redis_num_cache_nodes            = 1
  redis_node_type                  = "cache.t4g.small"
  redis_snapshot_retention_limit   = 1
  redis_family                     = "redis6.x"
  allowed_cidr_blocks_access_redis = []
  allowed_sg_ids_access_redis = [
    module.ecs.ecs_tasks_sg_id
  ]
  redis_parameters = {
    "maxmemory-policy" = "allkeys-lru"
  }
}

############################# SECRET MANAGER ############################
module "secret_manager" {
  source      = "./modules/secret_manager"
  project     = local.project
  tags        = local.tags
  secret_name = "todo-app-secret"
}

############################# PARAMETER STORE ############################
module "parameter_store" {
  source          = "./modules/parameter_store"
  project         = local.project
  tags            = local.tags
  source_services = ["be", "fe"]
}

################################ ECS #######################################
module "ecs" {
  source           = "./modules/ecs"
  project          = local.project
  tags             = local.tags
  vpc_id           = local.network.vpc_id
  lb_sg_id         = module.alb.lb_sg_id
  target_group_arn = module.alb.tg_arns["be"]
  subnets          = local.network.private_subnet_ids
  task_definitions = {
    "be" = {
      container_name       = "be"
      container_image      = "${local.project.account_id}.dkr.ecr.${local.project.region}.amazonaws.com/${module.ecr.ecr_name}:latest"
      desired_count        = 1
      cpu                  = 1024 # 1 vCPU
      memory               = 2048 # 2 GB RAM
      container_port       = 5000
      host_port            = 5000
      health_check_path    = "/health"
      enable_load_balancer = true
      load_balancer = {
        target_group_port = 5000
        container_port    = 5000
      }
    }
  }
}

############################# CICD ###############################
#-------------------FE pipeline----------------
module "pipeline_fe" {
  source            = "./modules/cicd/code_pipeline"
  project           = local.project
  tags              = local.tags
  project_name      = module.build_fe.project_name
  git_org           = local.git_repo.fe.organization
  git_repo          = local.git_repo.fe.name
  git_branch        = local.git_repo.fe.branch
  pipeline_name     = "fe"
  git_token         = var.github_token
  enable_ecs_deploy = false
  s3_force_del      = true
}

module "build_fe" {
  source         = "./modules/cicd/code_build"
  project        = local.project
  tags           = local.tags
  build_name     = "fe"
  buildspec_file = "${path.root}/scripts/pipeline/fe-buildspec.yml"
  env_vars_codebuild = {
    S3_BUCKET_NAME  = "${module.cloudfront.cfs3_bucket}"
    DISTRIBUTION_ID = "${module.cloudfront.distribution_id}"
    PARAMETER_STORE = "${module.parameter_store.parameter_name["fe"]}"
    GITHUB_TOKEN    = "${var.github_token}"
    GITHUB_REPO     = "${local.git_repo.fe.name}"
    GITHUB_BRANCH   = "${local.git_repo.fe.branch}"
    GITHUB_ORG      = "${local.git_repo.fe.organization}"
    GIT_URL         = "${local.git_repo.fe.url}"
    REGION          = "${local.project.region}"
  }
  codebuild_role_arn = module.pipeline_fe.codebuild_role_arn
}

# -------------------BE pipeline----------------
module "pipeline_be" {
  source            = "./modules/cicd/code_pipeline"
  project           = local.project
  tags              = local.tags
  project_name      = module.build_be.project_name
  git_org           = local.git_repo.be.organization
  git_repo          = local.git_repo.be.name
  git_branch        = local.git_repo.be.branch
  pipeline_name     = "be"
  git_token         = var.github_token
  enable_ecs_deploy = true
  ecs_cluster_name  = module.ecs.cluster_name
  ecs_service_name  = module.ecs.service_name["be"]
  s3_force_del      = true
}

module "build_be" {
  source         = "./modules/cicd/code_build"
  project        = local.project
  tags           = local.tags
  build_name     = "be"
  buildspec_file = "${path.root}/scripts/pipeline/be-buildspec.yml"
  env_vars_codebuild = {
    REGISTRY_URL     = "${module.ecr.ecr_url}"
    SERVICE          = "${module.ecs.service_name["be"]}"
    REGION           = "${local.project.region}"
    SSM_ENV          = "${module.parameter_store.parameter_name["be"]}"
    ECS_CLUSTER_NAME = "${module.ecs.cluster_name}"
    CONTAINER_NAME   = "${local.project.env}-${local.project.name}-be"
    ECR_IMAGE_TAG    = "latest"
    ECR_URL          = "${module.ecr.ecr_url}"
  }
  codebuild_role_arn = module.pipeline_be.codebuild_role_arn
}