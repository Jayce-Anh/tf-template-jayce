#---------------------------------Security Group---------------------------------
#Security Group
resource "aws_security_group" "sg_db" {
  name        = "${var.project.env}-${var.project.name}-${var.docdb_name}-sg"
  description = "SG for docdb ${var.docdb_name}"
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
  count                    = length(var.allowed_sg_ids_access_docdb)
  type                     = "ingress"
  from_port                = var.docdb_port
  to_port                  = var.docdb_port
  protocol                 = "TCP"
  source_security_group_id = var.allowed_sg_ids_access_docdb[count.index]
  security_group_id        = aws_security_group.sg_db.id
  description              = "From sg ${var.allowed_sg_ids_access_docdb[count.index]}"
}