module "redis" {
  source                           = "./modules/database/redis"
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