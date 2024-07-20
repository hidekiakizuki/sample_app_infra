# TODO: auroraにする
resource "aws_db_instance" "rds" {
  identifier = "rds-postgres"

  engine               = "postgres"
  engine_version       = var.rds.engine_version
  license_model        = "postgresql-license"
  parameter_group_name = aws_db_parameter_group.rds_pg.name

  network_type = "DUAL"
  port         = 5432

  username = data.aws_ssm_parameter.postgres_user.value
  password = data.aws_ssm_parameter.postgres_password.value

  instance_class        = var.rds.instance_class
  storage_type          = var.rds.storage_type
  allocated_storage     = var.rds.allocated_storage
  max_allocated_storage = var.rds.max_allocated_storage
  storage_encrypted     = true

  multi_az               = var.rds.multi_az
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  ca_cert_identifier     = "rds-ca-rsa2048-g1"
  kms_key_id             = aws_kms_key.rds.arn

  deletion_protection   = true
  skip_final_snapshot   = true
  copy_tags_to_snapshot = true

  backup_window            = "21:00-21:30" # AM6:00 〜 6:30 JST
  backup_retention_period  = 7
  delete_automated_backups = true

  maintenance_window         = "tue:18:00-tue:18:30" # 火曜 AM3:00 〜 3:30 JST
  auto_minor_version_upgrade = true

  monitoring_interval                   = 60
  monitoring_role_arn                   = aws_iam_role.rds_monitoring.arn
  enabled_cloudwatch_logs_exports       = ["postgresql", "upgrade"]
  performance_insights_enabled          = true
  performance_insights_kms_key_id       = aws_kms_key.rds.arn
  performance_insights_retention_period = 7

  tags = {
    Name = "rds-postgres"
  }
}

resource "aws_db_parameter_group" "rds_pg" {
  name   = "rds-postgres"
  family = var.rds.db_parameter_group.family

  parameter {
    name  = "lc_monetary"
    value = var.rds.db_parameter_group.lc_monetary
  }

  parameter {
    name  = "lc_numeric"
    value = var.rds.db_parameter_group.lc_numeric
  }

  parameter {
    name  = "lc_time"
    value = var.rds.db_parameter_group.lc_time
  }

  parameter {
    name  = "timezone"
    value = var.rds.db_parameter_group.timezone
  }

  parameter {
    name         = "autovacuum"
    value        = 1
    apply_method = "pending-reboot"
  }
}

resource "aws_db_subnet_group" "rds_subnet" {
  name = "rds-postgres"

  subnet_ids = tolist(aws_subnet.privates[*].id)
}

data "aws_ssm_parameter" "postgres_user" {
  name = "/rds/postgres/user"
}
data "aws_ssm_parameter" "postgres_password" {
  name = "/rds/postgres/password"
}
