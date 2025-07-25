module "rds" {
  source  = "./modules/database/rds"
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