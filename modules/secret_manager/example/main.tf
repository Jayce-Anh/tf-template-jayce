module "secret_manager" {
  source          = "./modules/secret_manager"
  project         = local.project
  tags            = local.tags
  secret_name     = "todo-app-secret"
}