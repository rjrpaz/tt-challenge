# --- database/main.tf ---

resource "aws_db_instance" "tt_db" {
  allocated_storage      = var.db_storage
  engine                 = "postgres"
  engine_version         = var.db_engine_version
  instance_class         = var.db_instance_class
  db_name                = var.dbname
  username               = var.dbuser
  password               = var.dbpassword
  db_subnet_group_name   = var.db_subnet_group_name[0]
  vpc_security_group_ids = [var.vpc_security_group_ids]
  identifier             = var.db_identifier
  #  skip_final_snapshot     = var.skip_db_snapshot
  # snapshot_identifier     = "tt-db-snapshot"
  backup_window           = "00:00-03:00"
  backup_retention_period = 5
  multi_az                = false

  # lifecycle {
  #   ignore_changes = [snapshot_identifier]
  # }
}

resource "aws_db_instance" "tt_db_replica" {
  allocated_storage   = var.db_storage
  replicate_source_db = aws_db_instance.tt_db.id
  instance_class      = var.db_instance_class
}
