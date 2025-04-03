module "parameter-be" {
  source          = "../../modules/parameter-store"
  project         = local.project
  source_services = ["be"]
}

module "parameter-fe" {
  source          = "../../modules/parameter-store"
  project         = local.project
  source_services = ["fe"]
}