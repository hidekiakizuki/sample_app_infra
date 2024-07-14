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
  enable_dns64                    = false # NAT gatewayをコメントアウトしているので一旦無効化します。

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
  enable_dns64                    = true # Egress-only internet gatewayを利用しているので有効化しています。

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

/*
コスト削減のため一旦コメントアウトします。
利用ケースとしては以下の通り
- PublicアドレスとしてIPv6しか持たないリソースから外部のIPv4対応のみの宛先に接続するケース
- Private Subnet からIPv4で外部へ出るケース
ただ、現状はPrivate SubnetからIPv4で外に出るケースはありません。

resource "aws_nat_gateway" "defaults" {
  count = length(var.zone_names)

  allocation_id = aws_eip.nats[count.index].id
  subnet_id     = aws_subnet.publics[count.index].id

  tags = {
    Name = "${var.zone_names[count.index]}"
  }
}

resource "aws_eip" "nats" {
  count = length(var.zone_names)

  domain = "vpc"

  tags = {
    Name = "nat-${var.zone_names[count.index]}"
  }
}
*/

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
  /*
  route {
    ipv6_cidr_block = local.ipv6_translation_prefix
    gateway_id      = aws_nat_gateway.defaults[count.index].id
  }
*/

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
  /*
  route {
    cidr_block     = local.open_access.ipv4.cidr_block
    nat_gateway_id = aws_nat_gateway.defaults[count.index].id
  }
*/

  route {
    ipv6_cidr_block        = local.open_access.ipv6.ipv6_cidr_block
    egress_only_gateway_id = aws_egress_only_internet_gateway.default.id
  }

  /*
  route {
    ipv6_cidr_block = "64:ff9b::/96"
    gateway_id      = aws_nat_gateway.defaults[count.index].id
  }
*/

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

resource "aws_security_group" "ecs" {
  name   = "ecs"
  vpc_id = aws_vpc.default.id

  tags = {
    Name = "ecs"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ecs" {
  security_group_id = aws_security_group.ecs.id

  referenced_security_group_id = aws_security_group.alb.id
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80

  tags = {
    Name = "alb-http"
  }
}

resource "aws_vpc_security_group_egress_rule" "ecs" {
  for_each = local.open_access

  security_group_id = aws_security_group.ecs.id

  cidr_ipv4   = each.value.cidr_block
  cidr_ipv6   = each.value.ipv6_cidr_block
  ip_protocol = "-1"

  tags = {
    Name = "open-access-${each.key}"
  }
}

resource "aws_security_group" "rds" {
  name   = "rds"
  vpc_id = aws_vpc.default.id

  tags = {
    Name = "rds"
  }
}

resource "aws_vpc_security_group_ingress_rule" "rds" {
  security_group_id = aws_security_group.rds.id

  referenced_security_group_id = aws_security_group.ecs.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432

  tags = {
    Name = "ecs-5432"
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
