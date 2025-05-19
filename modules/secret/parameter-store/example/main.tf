module "parameter-store" {
  source          = "../../modules/parameter-store"
  project         = local.project
  source_services = ["be", "fe"]
}

