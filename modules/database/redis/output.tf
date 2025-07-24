############################# OUTPUT #################################
output "redis_cluster_id" {
  value = aws_elasticache_cluster.redis.id
} 

output "redis_cluster_endpoint" {
  value = aws_elasticache_cluster.redis.cluster_address
}




