############################# OUTPUT #################################
output "redis_cluster_id" {
  value = aws_elasticache_cluster.redis.id
} 

output "redis_cluster_endpoint" {
  value = aws_elasticache_cluster.redis.cache_nodes[0].address
}

output "redis_cluster_port" {
  value = aws_elasticache_cluster.redis.cache_nodes[0].port
}




