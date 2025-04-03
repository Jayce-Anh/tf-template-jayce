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