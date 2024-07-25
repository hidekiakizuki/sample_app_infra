resource "aws_cloudfront_distribution" "rails_web" {
  origin {
    domain_name = aws_lb.alb.dns_name
    origin_id   = aws_lb.alb.dns_name

    custom_origin_config {
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
      http_port              = 80
      https_port             = 443
    }
  }

  enabled          = var.service_suspend_mode ? false : true
  is_ipv6_enabled  = true
  retain_on_delete = true

  aliases    = [var.app_domain_name]

  # コスト削減のためnullにします。
  web_acl_id = null # aws_wafv2_web_acl.cloudfront_active.arn

  default_cache_behavior {
    cache_policy_id          = aws_cloudfront_cache_policy.rails_web.id
    allowed_methods          = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods           = ["GET", "HEAD"]
    target_origin_id         = aws_lb.alb.dns_name
    origin_request_policy_id = aws_cloudfront_origin_request_policy.rails_web.id
    compress                 = true
    viewer_protocol_policy   = "redirect-to-https"
  }

  price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn            = data.aws_acm_certificate.virginia.arn
    minimum_protocol_version       = "TLSv1.2_2021"
    ssl_support_method             = "sni-only"
  }
}

data "aws_acm_certificate" "virginia" {
  provider = aws.virginia
  domain   = var.root_domain_name
}

resource "aws_cloudfront_origin_request_policy" "rails_web" {
  name    = "all-viewer"
  comment = "Policy to forward all parameters in viewer requests"

  cookies_config {
    cookie_behavior = "all"
  }

  headers_config {
    header_behavior = "allViewer"
  }

  query_strings_config {
    query_string_behavior = "all"
  }
}

resource "aws_cloudfront_cache_policy" "rails_web" {
  name        = "caching-disabled"
  comment     = "Policy with caching disabled"
  default_ttl = 0
  max_ttl     = 0
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_brotli = false
    enable_accept_encoding_gzip   = false

    cookies_config {
      cookie_behavior = "none"
    }

    headers_config {
      header_behavior = "none"
    }

    query_strings_config {
      query_string_behavior = "none"
    }
  }
}
