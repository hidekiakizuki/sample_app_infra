resource "aws_vpc" "default" {
  cidr_block                           = "10.0.0.0/16"
  assign_generated_ipv6_cidr_block     = true
  enable_dns_hostnames                 = true
  enable_dns_support                   = true
  enable_network_address_usage_metrics = true
}

resource "aws_subnet" "publics" {
  count = length(var.zone_names)

  vpc_id            = aws_vpc.default.id
  availability_zone = var.zone_names[count.index]

  # 10.0.0.0/20, 10.0.16.0/20, 10.0.32.0/20
  cidr_block = cidrsubnet(aws_vpc.default.cidr_block, 4, count.index)

  # xxxx:xxxx:xxxx:xxx0::/64, xxxx:xxxx:xxxx:xxx1::/64, xxxx:xxxx:xxxx:xxx2::/64
  ipv6_cidr_block = cidrsubnet(aws_vpc.default.ipv6_cidr_block, 8, count.index)

  assign_ipv6_address_on_creation = true
  enable_dns64                    = true

  tags = {
    Name = "public-${var.zone_names[count.index]}"
  }
}

resource "aws_subnet" "privates" {
  count = length(var.zone_names)

  vpc_id            = aws_vpc.default.id
  availability_zone = var.zone_names[count.index]

  # 10.0.128.0/20, 10.0.144.0/20, 10.0.160.0/20
  cidr_block = cidrsubnet(aws_vpc.default.cidr_block, 4, count.index + 8)

  # xxxx:xxxx:xxxx:xx80::/64, xxxx:xxxx:xxxx:xx81::/64, xxxx:xxxx:xxxx:xx82::/64
  ipv6_cidr_block = cidrsubnet("${cidrsubnet(aws_vpc.default.ipv6_cidr_block, 1, 1)}", 7, count.index)

  assign_ipv6_address_on_creation = true
  enable_dns64                    = true

  tags = {
    Name = "private-${var.zone_names[count.index]}"
  }
}

resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id
}

resource "aws_egress_only_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id
}

resource "aws_nat_gateway" "defaults" {
  count = var.service_suspend_mode ? 0 : length(var.zone_names)

  allocation_id = aws_eip.nats[count.index].id
  subnet_id     = aws_subnet.publics[count.index].id

  tags = {
    Name = "${var.zone_names[count.index]}"
  }
}

resource "aws_eip" "nats" {
  count = var.service_suspend_mode ? 0 : length(var.zone_names)

  domain = "vpc"

  tags = {
    Name = "nat-${var.zone_names[count.index]}"
  }
}

resource "aws_route_table" "publics" {
  count = length(var.zone_names)

  vpc_id = aws_vpc.default.id

  route {
    cidr_block = local.open_access.ipv4.cidr_block
    gateway_id = aws_internet_gateway.default.id
  }

  route {
    ipv6_cidr_block = local.open_access.ipv6.ipv6_cidr_block
    gateway_id      = aws_internet_gateway.default.id
  }

  dynamic "route" {
    for_each = var.service_suspend_mode ? [] : [1]

    content {
      ipv6_cidr_block = local.ipv6_translation_prefix
      gateway_id      = aws_nat_gateway.defaults[count.index].id
    }
  }

  route {
    cidr_block = aws_vpc.default.cidr_block
    gateway_id = "local"
  }

  route {
    ipv6_cidr_block = aws_vpc.default.ipv6_cidr_block
    gateway_id      = "local"
  }

  tags = {
    Name = "public-${var.zone_names[count.index]}"
  }
}

resource "aws_route_table" "privates" {
  count = length(var.zone_names)

  vpc_id = aws_vpc.default.id

  dynamic "route" {
    for_each = var.service_suspend_mode ? [] : [1]

    content {
      cidr_block     = local.open_access.ipv4.cidr_block
      nat_gateway_id = aws_nat_gateway.defaults[count.index].id
    }
  }

  route {
    ipv6_cidr_block        = local.open_access.ipv6.ipv6_cidr_block
    egress_only_gateway_id = aws_egress_only_internet_gateway.default.id
  }

  dynamic "route" {
    for_each = var.service_suspend_mode ? [] : [1]

    content {
      ipv6_cidr_block = local.ipv6_translation_prefix
      gateway_id      = aws_nat_gateway.defaults[count.index].id
    }
  }

  route {
    cidr_block = aws_vpc.default.cidr_block
    gateway_id = "local"
  }

  route {
    ipv6_cidr_block = aws_vpc.default.ipv6_cidr_block
    gateway_id      = "local"
  }

  tags = {
    Name = "private-${var.zone_names[count.index]}"
  }
}

resource "aws_route_table_association" "publics" {
  count = length(var.zone_names)

  route_table_id = aws_route_table.publics[count.index].id
  subnet_id      = aws_subnet.publics[count.index].id
}

resource "aws_route_table_association" "privates" {
  count = length(var.zone_names)

  route_table_id = aws_route_table.privates[count.index].id
  subnet_id      = aws_subnet.privates[count.index].id
}

/*
resource "aws_flow_log" "default" {
  log_destination      = aws_s3_bucket.flow_log_default.arn
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.default.id
}
*/