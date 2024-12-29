# --- ALB -------------------------------------------------------------------
resource "aws_security_group" "alb" {
  name   = "alb"
  vpc_id = aws_vpc.default.id

  tags = {
    Name = "alb"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  for_each = local.open_access

  security_group_id = aws_security_group.alb.id

  cidr_ipv4   = each.value.cidr_block
  cidr_ipv6   = each.value.ipv6_cidr_block
  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443

  tags = {
    Name = "open-access-https-${each.key}"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  for_each = local.open_access

  security_group_id = aws_security_group.alb.id

  cidr_ipv4   = each.value.cidr_block
  cidr_ipv6   = each.value.ipv6_cidr_block
  ip_protocol = "tcp"
  from_port   = 80
  to_port     = 80

  tags = {
    Name = "open-access-http-${each.key}"
  }
}

resource "aws_vpc_security_group_egress_rule" "alb" {
  for_each = local.open_access

  security_group_id = aws_security_group.alb.id

  cidr_ipv4   = each.value.cidr_block
  cidr_ipv6   = each.value.ipv6_cidr_block
  ip_protocol = "-1"

  tags = {
    Name = "open-access-${each.key}"
  }
}

# --- ECSコンテナ -----------------------------------------------------------------
# web
resource "aws_security_group" "web" {
  name   = "web"
  vpc_id = aws_vpc.default.id

  tags = {
    Name = "web"
  }
}

resource "aws_vpc_security_group_ingress_rule" "web" {
  security_group_id = aws_security_group.web.id

  referenced_security_group_id = aws_security_group.alb.id
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80

  tags = {
    Name = "alb-http"
  }
}

resource "aws_vpc_security_group_egress_rule" "web" {
  for_each = local.open_access

  security_group_id = aws_security_group.web.id

  cidr_ipv4   = each.value.cidr_block
  cidr_ipv6   = each.value.ipv6_cidr_block
  ip_protocol = "-1"

  tags = {
    Name = "open-access-${each.key}"
  }
}

# worker
resource "aws_security_group" "worker" {
  name   = "worker"
  vpc_id = aws_vpc.default.id

  tags = {
    Name = "worker"
  }
}

resource "aws_vpc_security_group_egress_rule" "worker" {
  for_each = local.open_access

  security_group_id = aws_security_group.worker.id

  cidr_ipv4   = each.value.cidr_block
  cidr_ipv6   = each.value.ipv6_cidr_block
  ip_protocol = "-1"

  tags = {
    Name = "open-access-${each.key}"
  }
}

# batch
resource "aws_security_group" "batch" {
  name   = "batch"
  vpc_id = aws_vpc.default.id

  tags = {
    Name = "batch"
  }
}

resource "aws_vpc_security_group_egress_rule" "batch" {
  for_each = local.open_access

  security_group_id = aws_security_group.batch.id

  cidr_ipv4   = each.value.cidr_block
  cidr_ipv6   = each.value.ipv6_cidr_block
  ip_protocol = "-1"

  tags = {
    Name = "open-access-${each.key}"
  }
}

# --- RDS ------------------------------------------------------------------------
resource "aws_security_group" "rds" {
  name   = "rds"
  vpc_id = aws_vpc.default.id

  tags = {
    Name = "rds"
  }
}

resource "aws_vpc_security_group_ingress_rule" "rds_web" {
  security_group_id = aws_security_group.rds.id

  referenced_security_group_id = aws_security_group.web.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432

  tags = {
    Name = "web-5432"
  }
}

resource "aws_vpc_security_group_ingress_rule" "rds_worker" {
  security_group_id = aws_security_group.rds.id

  referenced_security_group_id = aws_security_group.worker.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432

  tags = {
    Name = "worker-5432"
  }
}

resource "aws_vpc_security_group_ingress_rule" "rds_batch" {
  security_group_id = aws_security_group.rds.id

  referenced_security_group_id = aws_security_group.batch.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432

  tags = {
    Name = "batch-5432"
  }
}

resource "aws_vpc_security_group_egress_rule" "rds" {
  for_each = local.open_access

  security_group_id = aws_security_group.rds.id

  cidr_ipv4   = each.value.cidr_block
  cidr_ipv6   = each.value.ipv6_cidr_block
  ip_protocol = "-1"

  tags = {
    Name = "open-access-${each.key}"
  }
}

# --- VPCエンドポイント (Interfaceタイプ) --------------------------------------------
resource "aws_security_group" "vpc_endpoint_default" {
  name = "vpc-endpoint-default"
  vpc_id = aws_vpc.default.id

  tags = {
    Name = "vpc-endpoint"
  }
}

resource "aws_vpc_security_group_ingress_rule" "vpc_endpoint_default_ipv4" {
  security_group_id = aws_security_group.vpc_endpoint_default.id

  cidr_ipv4   = aws_vpc.default.cidr_block
  ip_protocol = "-1"

  tags = {
    Name = "vpc-endpoint-ipv4-https-access"
  }
}

resource "aws_vpc_security_group_ingress_rule" "vpc_endpoint_default_ipv6" {
  security_group_id = aws_security_group.vpc_endpoint_default.id

  cidr_ipv6   = aws_vpc.default.ipv6_cidr_block
  ip_protocol = "-1"

  tags = {
    Name = "vpc-endpoint-ipv6-https-access"
  }
}

resource "aws_vpc_security_group_egress_rule" "vpc_endpoint_default" {
  for_each = local.open_access

  security_group_id = aws_security_group.vpc_endpoint_default.id

  cidr_ipv4   = each.value.cidr_block
  cidr_ipv6   = each.value.ipv6_cidr_block
  ip_protocol = "-1"

  tags = {
    Name = "vpc-endpoint-open-access-${each.key}"
  }
}

# --- ElastiCache -------------------------------------------------------------
resource "aws_security_group" "elasticache_default" {
  name        = "elasticache-default"
  vpc_id      = aws_vpc.default.id

  tags = {
    Name = "elasticache"
  }
}

resource "aws_vpc_security_group_ingress_rule" "elasticache_default_ipv4" {
  for_each = local.elacti_cache_ports

  security_group_id = aws_security_group.elasticache_default.id

  cidr_ipv4   = aws_vpc.default.cidr_block
  ip_protocol = "tcp"
  from_port   = each.value
  to_port     = each.value

  tags = {
    Name = "elasticache-ipv4-${each.key}-access"
  }
}

resource "aws_vpc_security_group_ingress_rule" "elasticache_default_ipv6" {
  for_each = local.elacti_cache_ports

  security_group_id = aws_security_group.elasticache_default.id

  cidr_ipv6   = aws_vpc.default.ipv6_cidr_block
  ip_protocol = "tcp"
  from_port   = each.value
  to_port     = each.value

  tags = {
    Name = "elasticache-ipv6-${each.key}-access"
  }
}

resource "aws_vpc_security_group_egress_rule" "elasticache_default" {
  for_each = local.open_access

  security_group_id = aws_security_group.elasticache_default.id

  cidr_ipv4   = each.value.cidr_block
  cidr_ipv6   = each.value.ipv6_cidr_block
  ip_protocol = "-1"

  tags = {
    Name = "elasticache-open-access-${each.key}"
  }
}
