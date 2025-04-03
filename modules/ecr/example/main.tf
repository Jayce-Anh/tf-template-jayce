module "ecr_be" {
  source          = "./modules/ecr"
  project         = local.project
  source_services = ["be"]
}

module "ecr_fe" {
  source          = "./modules/ecr"
  project         = local.project
  source_services = ["fe"]
}
