resource "aws_lb" "alb" {
  name                       = "alb"
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb.id]
  subnets                    = tolist(aws_subnet.publics[*].id)
  ip_address_type            = "dualstack"
  enable_deletion_protection = true
}

resource "aws_lb_listener" "rails_web_https" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = data.aws_acm_certificate.app_region.arn

  default_action {
    type             = "forward"
    target_group_arn = local.current_https_target_group_arn
  }
  tags = {
    Name = "https-to-ecs"
  }
}

resource "aws_lb_listener" "rails_web_http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "redirect"
    redirect {
      host        = "#{host}"
      path        = "/#{path}"
      port        = "443"
      protocol    = "HTTPS"
      query       = "#{query}"
      status_code = "HTTP_301"
    }
  }
  tags = {
    Name = "redirect-http-to-https"
  }
}

resource "aws_lb_listener" "rails_web_test" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 8080
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = local.current_https_target_group_arn
  }
  tags = {
    Name = "test-http-8080-to-ecs"
  }
}

resource "aws_lb_target_group" "rails_web_b" {
  name            = "rails-web-b"
  port            = 80
  protocol        = "HTTP"
  target_type     = "ip"
  ip_address_type = "ipv4"
  vpc_id          = aws_vpc.default.id

  health_check {
    healthy_threshold = 5
    path              = "/healthy"
  }
}

resource "aws_lb_target_group" "rails_web_g" {
  name            = "rails-web-g"
  port            = 80
  protocol        = "HTTP"
  target_type     = "ip"
  ip_address_type = "ipv4"
  vpc_id          = aws_vpc.default.id

  health_check {
    healthy_threshold = 5
    path              = "/healthy"
  }
}

data "aws_acm_certificate" "app_region" {
  domain = var.root_domain_name
}

data "aws_lb_listener" "current_https" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 443
}

data "external" "current_https_target_group_arn" {
  program = [
    "aws", "elbv2", "describe-listeners",
    "--listener-arns", data.aws_lb_listener.current_https.arn,
    "--query", "{\"arn\": to_string(Listeners[0].DefaultActions[0].TargetGroupArn)}"
  ]
}

locals {
  current_https_target_group_arn = contains(["null", null], data.external.current_https_target_group_arn.result.arn) ? aws_lb_target_group.rails_web_b.arn : data.external.current_https_target_group_arn.result.arn
}
