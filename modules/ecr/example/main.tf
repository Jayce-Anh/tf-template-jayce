module "ecr" {
  source          = "./modules/ecr"
  project         = local.project
  tags            = local.tags
  source_services = ["be", "fe"]
  s3_force_del = true
}