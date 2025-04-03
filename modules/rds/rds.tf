#---------------------------------Security Group---------------------------------
#Security Group
resource "aws_security_group" "sg_db" {
  name        = "${var.project.env}-${var.project.name}-sg-rds-${var.rds_name}"
  description = "SG for db ${var.rds_name}"
  vpc_id      = var.network.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Security Group Rule
resource "aws_security_group_rule" "sg_rule_from_sg_id" {
  count                    = length(var.allowed_sg_ids_access_rds)
  type                     = "ingress"
  from_port                = var.rds_port
  to_port                  = var.rds_port
  protocol                 = "TCP"
  source_security_group_id = var.allowed_sg_ids_access_rds[count.index]
  security_group_id        = aws_security_group.sg_db.id
  description              = "From sg ${var.allowed_sg_ids_access_rds[count.index]}"
}

#---------------------------------Parameter Group---------------------------------
resource "aws_db_parameter_group" "db_parameter_group" {
  name   = "${var.project.env}-${var.project.name}-${var.rds_name}"
  family = var.rds_family
  dynamic "parameter" {
    for_each = var.aws_db_parameters
    content {
      name  = parameter.key
      value = parameter.value
      apply_method = "pending-reboot"
    }
  }
  lifecycle {
    ignore_changes = [parameter]
  }
}

#---------------------------------Subnet Group---------------------------------
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "${var.project.env}-${var.project.name}-${var.rds_name}"
  subnet_ids = var.network.private_subnet_ids
}

#---------------------------------RDS Instance---------------------------------
resource "aws_db_instance" "db" {
  identifier            = "${var.project.env}-${var.project.name}-${var.rds_name}"
  multi_az              = var.multi_az
  allocated_storage     = var.rds_storage
  max_allocated_storage = var.rds_max_storage

  storage_type       = var.rds_storage_type
  iops               = (var.rds_storage_type == "io1") || (var.rds_storage_type == "gp3" && var.rds_storage > 400) ? var.rds_iops : null 
  storage_throughput = (var.rds_storage_type == "gp3" && var.rds_storage > 400) ? var.rds_throughput : null

  engine                 = var.rds_engine
  engine_version         = var.rds_engine_version
  instance_class         = var.rds_class
  db_name                = replace("${var.rds_name}", "-", "_")
  username               = var.rds_username
  password               = var.rds_password
  port                   = var.rds_port
  parameter_group_name   = aws_db_parameter_group.db_parameter_group.name
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.sg_db.id]

  performance_insights_enabled          = false
  performance_insights_retention_period = var.performance_insights_retention_period
  skip_final_snapshot                   = true # if you want snapshot before deleteing set to false

  # apply_immediately = true
  # final_snapshot_identifier = "${var.common.env}-${var.common.project}-${var.rds_name}-final"

  allow_major_version_upgrade = false
  auto_minor_version_upgrade  = false

  lifecycle {
    ignore_changes = [publicly_accessible, engine_version]
  }
  backup_retention_period = var.rds_backup_retention_period
  backup_window           = "00:30-01:30"
  maintenance_window      = "sat:04:30-sat:05:30"
  tags                    = {
    name = "${var.project.env}-${var.project.name}-${var.rds_name}"
    env  = "${var.project.env}"
  }
}


