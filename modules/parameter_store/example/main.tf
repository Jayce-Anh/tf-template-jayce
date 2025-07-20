module "parameter_store" {
  source      = "./modules/parameter_store"
  project     = local.project
  tags        = local.tags
  source_services = ["be", "fe"] #list of services to create parameter store
}