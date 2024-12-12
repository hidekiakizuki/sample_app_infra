# --- Gatewayタイプ ----------------------------------------------------------------
resource "aws_vpc_endpoint" "s3" {
  count = var.service_suspend_mode ? 0 : 1

  vpc_id            = aws_vpc.default.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"

  tags = {
    Name = "s3"
  }
}

resource "aws_vpc_endpoint_route_table_association" "s3" {
  count = var.service_suspend_mode ? 0 : length(var.zone_names)

  route_table_id  = aws_route_table.privates[count.index].id
  vpc_endpoint_id = aws_vpc_endpoint.s3[0].id
}

resource "aws_vpc_endpoint" "dynamodb" {
  count = var.service_suspend_mode ? 0 : 1

  vpc_id            = aws_vpc.default.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.dynamodb"
  vpc_endpoint_type = "Gateway"

  tags = {
    Name = "dynamodb"
  }
}

resource "aws_vpc_endpoint_route_table_association" "dynamodb" {
  count = var.service_suspend_mode ? 0 : length(var.zone_names)

  route_table_id  = aws_route_table.privates[count.index].id
  vpc_endpoint_id = aws_vpc_endpoint.dynamodb[0].id
}

# --- Interfaceタイプ -------------------------------------------------------------
resource "aws_vpc_endpoint" "ecr_api" {
  count = var.service_suspend_mode ? 0 : 1

  vpc_id            = aws_vpc.default.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.vpc_endpoint_default.id
  ]

  subnet_ids          = tolist(aws_subnet.privates[*].id)
  private_dns_enabled = true

  tags = {
    Name = "ecr-api"
  }
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  count = var.service_suspend_mode ? 0 : 1

  vpc_id            = aws_vpc.default.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.vpc_endpoint_default.id
  ]

  subnet_ids          = tolist(aws_subnet.privates[*].id)
  private_dns_enabled = true

  tags = {
    Name = "ecr-dkr"
  }
}

resource "aws_vpc_endpoint" "secrets_manager" {
  count = var.service_suspend_mode ? 0 : 1

  vpc_id            = aws_vpc.default.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.secretsmanager"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.vpc_endpoint_default.id
  ]

  subnet_ids          = tolist(aws_subnet.privates[*].id)
  private_dns_enabled = true

  tags = {
    Name = "secrets-manager"
  }
}

resource "aws_vpc_endpoint" "ssm" {
  count = var.service_suspend_mode ? 0 : 1

  vpc_id            = aws_vpc.default.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.ssm"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.vpc_endpoint_default.id
  ]

  subnet_ids          = tolist(aws_subnet.privates[*].id)
  private_dns_enabled = true

  tags = {
    Name = "ssm"
  }
}

resource "aws_vpc_endpoint" "ssm_messages" {
  count = var.service_suspend_mode ? 0 : 1

  vpc_id            = aws_vpc.default.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.ssmmessages"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.vpc_endpoint_default.id
  ]

  subnet_ids          = tolist(aws_subnet.privates[*].id)
  private_dns_enabled = true

  tags = {
    Name = "ssm-messages"
  }
}

resource "aws_vpc_endpoint" "cloud_watch_logs" {
  count = var.service_suspend_mode ? 0 : 1

  vpc_id            = aws_vpc.default.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.logs"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.vpc_endpoint_default.id
  ]

  subnet_ids          = tolist(aws_subnet.privates[*].id)
  private_dns_enabled = true

  tags = {
    Name = "cloud-watch-logs"
  }
}

resource "aws_vpc_endpoint" "firehose" {
  count = var.service_suspend_mode ? 0 : 1

  vpc_id            = aws_vpc.default.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.kinesis-firehose"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.vpc_endpoint_default.id
  ]

  subnet_ids          = tolist(aws_subnet.privates[*].id)
  private_dns_enabled = true

  tags = {
    Name = "firehose"
  }
}

resource "aws_vpc_endpoint" "sns" {
  count = var.service_suspend_mode ? 0 : 1

  vpc_id            = aws_vpc.default.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.sns"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.vpc_endpoint_default.id
  ]

  subnet_ids          = tolist(aws_subnet.privates[*].id)
  private_dns_enabled = true

  tags = {
    Name = "sns"
  }
}

resource "aws_vpc_endpoint" "sqs" {
  count = var.service_suspend_mode ? 0 : 1

  vpc_id            = aws_vpc.default.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.sqs"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.vpc_endpoint_default.id,
  ]

  subnet_ids          = tolist(aws_subnet.privates[*].id)
  private_dns_enabled = true

  tags = {
    Name = "sqs"
  }
}
