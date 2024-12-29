resource "aws_elasticache_serverless_cache" "default" {
  count = var.service_suspend_mode ? 0 : 1

  engine = "redis"
  name   = "default"

  cache_usage_limits {
    data_storage {
      maximum = 10
      unit    = "GB"
    }
    ecpu_per_second {
      maximum = 5000
    }
  }

  daily_snapshot_time      = "19:00" # JST 04:00
  kms_key_id               = aws_kms_key.elasticache.arn
  major_engine_version     = "7"
  snapshot_retention_limit = 1
  security_group_ids       = [aws_security_group.elasticache_default.id]
  subnet_ids               = tolist(aws_subnet.privates[*].id)
  user_group_id            = aws_elasticache_user_group.default.id
}

resource "aws_elasticache_user_group" "default" {
  engine        = "REDIS"
  user_group_id = "default"
  user_ids = [
    aws_elasticache_user.default_dummy.user_id,
    aws_elasticache_user.default_admin.user_id,
    aws_elasticache_user.default_custom.user_id,
  ]
}

# defaultという名前のユーザーが必ず一つ必要ですが、
# セキュリティのために何もできないようにします。
resource "aws_elasticache_user" "default_dummy" {
  user_id       = "default-dummy"
  user_name     = "default"
  access_string = "on ~* -@all"
  engine        = "REDIS"

  authentication_mode {
    type = "password"
    passwords = [data.aws_ssm_parameter.elasticache_default_dummy_password.value]
  }
}

resource "aws_elasticache_user" "default_admin" {
  user_id       = "default-admin"
  user_name     = data.aws_ssm_parameter.elasticache_default_admin_user.value
  access_string = "on ~* +@all"
  engine        = "REDIS"

  authentication_mode {
    type = "password"
    passwords = [data.aws_ssm_parameter.elasticache_default_admin_password.value]
  }
}

resource "aws_elasticache_user" "default_custom" {
  user_id       = "default-custom"
  user_name     = data.aws_ssm_parameter.elasticache_default_custom_user.value
  access_string = "on ~* +@all -@admin"
  engine        = "REDIS"

  authentication_mode {
    type = "password"
    passwords = [data.aws_ssm_parameter.elasticache_default_custom_password.value]
  }
}

data "aws_ssm_parameter" "elasticache_default_dummy_password" {
  name = "/elasticache/default-dummy/password"
}
data "aws_ssm_parameter" "elasticache_default_admin_user" {
  name = "/elasticache/default-admin/user"
}
data "aws_ssm_parameter" "elasticache_default_admin_password" {
  name = "/elasticache/default-admin/password"
}
data "aws_ssm_parameter" "elasticache_default_custom_user" {
  name = "/elasticache/default-custom/user"
}
data "aws_ssm_parameter" "elasticache_default_custom_password" {
  name = "/elasticache/default-custom/password"
}
