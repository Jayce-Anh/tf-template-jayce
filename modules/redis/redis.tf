#-----------------Elasticache Subnet group-----------------
resource "aws_elasticache_subnet_group" "subnet_group" {
  name       = "${var.project.env}-${var.project.name}-cache-${var.redis_name}"
  subnet_ids = var.network.private_subnet_ids
}

#-----------------Elasticache Security group-----------------
resource "aws_security_group" "sg" {
  name        = "${var.project.env}-${var.project.name}-sg-redis-${var.redis_name}"
  description = "SG for redis ${var.redis_name}"
  vpc_id      = var.network.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Elasticache Security group rule
resource "aws_security_group_rule" "sg_rule_redis_from_sg_ids" {
  count = length(var.allowed_sg_ids_access_redis)

  type                     = "ingress"
  from_port                = var.redis_port
  to_port                  = var.redis_port
  protocol                 = "TCP"
  source_security_group_id = var.allowed_sg_ids_access_redis[count.index]
  security_group_id        = aws_security_group.sg.id
  description              = "From sg ${var.allowed_sg_ids_access_redis[count.index]}"
}

resource "aws_security_group_rule" "sg_rule_redis_from_cidr_blocks" {
  count = length(var.allowed_cidr_blocks_access_redis)

  type              = "ingress"
  from_port         = var.redis_port
  to_port           = var.redis_port
  protocol          = "TCP"
  cidr_blocks       = var.allowed_cidr_blocks_access_redis
  security_group_id = aws_security_group.sg.id
  description       = "From cidr ${var.allowed_cidr_blocks_access_redis[count.index]}"
}


#-----------------Elasticache Parameter group-----------------
resource "aws_elasticache_parameter_group" "parameter_group" {
  name   = "${var.common.env}-${var.common.project}-${var.redis_name}"
  family = var.redis_family

  dynamic "parameter" {
    for_each = var.redis_parameters
    content {
      name  = parameter.key
      value = parameter.value
    }
  }
}

#-----------------Elasticache Redis Instance-----------------
resource "aws_elasticache_cluster" "redis" {
  cluster_id      = "${var.common.env}-${var.common.project}-${var.redis_name}"
  engine          = var.redis_engine
  node_type       = var.redis_node_type
  num_cache_nodes = var.redis_num_cache_nodes
  engine_version  = var.redis_engine_version
  port            = var.redis_port

  subnet_group_name    = aws_elasticache_subnet_group.subnet_group.name
  parameter_group_name = aws_elasticache_parameter_group.parameter_group.name
  security_group_ids   = [aws_security_group.sg.id]

  auto_minor_version_upgrade = false
  apply_immediately          = true

  snapshot_window          = "00:30-01:30"
  snapshot_retention_limit = var.redis_snapshot_retention_limit
  maintenance_window       = "sat:04:30-sat:05:30"
  tags                     = {
    name = "${var.common.env}-${var.common.project}-${var.redis_name}"
    env  = "${var.common.env}"
  }
}

