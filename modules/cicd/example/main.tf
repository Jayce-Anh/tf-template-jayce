module "code_pipeline" {
  source        = "./modules/cicd/code_pipeline"
  project       = local.project
  project_name  = "${module.code_build.project_name}"
  git_org       = local.git_repo.fe.organization
  git_repo      = local.git_repo.fe.name
  git_branch    = local.git_repo.fe.branch
  pipeline_name = "fe"
  git_token     = var.git_token
}

module "code_build" {
  source         = "./modules/cicd/code_build"
  project        = local.project
  buildspec_file = "${path.module}/modules/cicd/pipeline/fe-buildspec.yml"
  env_vars_codebuild = {
    S3_BUCKET_NAME  = "${module.cloudfront.cfs3_bucket}"
    DISTRIBUTION_ID = "${module.cloudfront.distribution_id}"
    PARAMETER_STORE = "/${local.project.env}/${local.project.name}/fe/env"
    GITHUB_TOKEN    = "${var.git_token}"
    GITHUB_REPO     = "${local.git_repo.fe.name}"
    GITHUB_BRANCH   = "${local.git_repo.fe.branch}"
    GITHUB_ORG      = "${local.git_repo.fe.organization}"
    REGION          = "${local.project.region}"
  }
  codebuild_role_arn = module.code_pipeline.codebuild_role_arn
}

