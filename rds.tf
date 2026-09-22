# ==============================
# DB Subnet Group
# ==============================

resource "aws_db_subnet_group" "main" {
  name = "${var.project_name}-db-subnet-group"

  subnet_ids = [
    aws_subnet.db_1a.id,
    aws_subnet.db_1c.id
  ]

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# ==============================
# RDS PostgreSQL
# ==============================

resource "aws_db_instance" "postgres" {
  identifier = "${var.project_name}-postgres"

  engine         = "postgres"
  instance_class = var.db_instance_class

  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username

  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  multi_az            = true
  publicly_accessible = false

  backup_retention_period = 1

  deletion_protection = false
  skip_final_snapshot = true

  tags = {
    Name = "${var.project_name}-postgres"
  }
}
