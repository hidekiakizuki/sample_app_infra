resource "aws_s3_bucket" "terraform_state" {
  bucket        = "terraform-state-${data.aws_caller_identity.current.account_id}"
  force_destroy = false
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.bucket

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket" "elb_logs" {
  bucket        = "elb-logs-${data.aws_caller_identity.current.account_id}"
  force_destroy = false
}

resource "aws_s3_bucket_policy" "elb_logs" {
  bucket = aws_s3_bucket.elb_logs.id
  policy = data.aws_iam_policy_document.elb_logs.json
}

data "aws_iam_policy_document" "elb_logs" {
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_elb_service_account.current.id}:root"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.elb_logs.arn}/*"]
  }

  version = "2012-10-17"
}

resource "aws_s3_bucket" "cloud_watch_logs_backups" {
  bucket        = "cloud-watch-logs-backups-${data.aws_caller_identity.current.account_id}"
  force_destroy = false
}

resource "aws_s3_bucket_policy" "cloud_watch_logs_backups" {
  bucket = aws_s3_bucket.cloud_watch_logs_backups.id
  policy = data.aws_iam_policy_document.cloud_watch_logs_backups.json
}

data "aws_iam_policy_document" "cloud_watch_logs_backups" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logs.${data.aws_region.current.name}.amazonaws.com"]
    }

    actions = ["s3:GetBucketAcl"]

    resources = [aws_s3_bucket.cloud_watch_logs_backups.arn]

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:*"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = ["${data.aws_caller_identity.current.account_id}"]
    }
  }

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logs.${data.aws_region.current.name}.amazonaws.com"]
    }

    actions = ["s3:PutObject"]

    resources = ["${aws_s3_bucket.cloud_watch_logs_backups.arn}/*"]

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:*"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = ["${data.aws_caller_identity.current.account_id}"]
    }

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  version = "2012-10-17"
}

resource "aws_s3_bucket_lifecycle_configuration" "cloud_watch_logs_backups" {
  bucket = aws_s3_bucket.cloud_watch_logs_backups.bucket

  rule {
    id = "delete_logs"

    expiration {
      days = 365
    }

    status = "Enabled"
  }
}

resource "aws_s3_bucket" "fluent_bit_config" {
  bucket        = "fluent-bit-config-${data.aws_caller_identity.current.account_id}"
  force_destroy = false
}

resource "aws_s3_object" "web_extra" {
  bucket = aws_s3_bucket.fluent_bit_config.bucket
  key    = "web_extra.conf"
  source = "${path.module}/files/conf/fluent-bit/web_extra.conf"

  etag = filemd5("${path.module}/files/conf/fluent-bit/web_extra.conf")
}

/*
将来、AWS BatchがFireLensに対応したときのためにおいておきます。現在は使用できません。
resource "aws_s3_object" "batch_extra" {
  bucket = aws_s3_bucket.fluent_bit_config.bucket
  key    = "batch_extra.conf"
  source = "${path.module}/files/conf/fluent-bit/batch_extra.conf"

  etag   = filemd5("${path.module}/files/conf/fluent-bit/batch_extra.conf")
}
*/

resource "aws_s3_object" "web_app_log_parser" {
  bucket = aws_s3_bucket.fluent_bit_config.bucket
  key    = "web_app_log_parser.conf"
  source = "${path.module}/files/conf/fluent-bit/web_app_log_parser.conf"

  etag = filemd5("${path.module}/files/conf/fluent-bit/web_app_log_parser.conf")
}

resource "aws_s3_object" "nginx_access_log_parser" {
  bucket = aws_s3_bucket.fluent_bit_config.bucket
  key    = "nginx_access_log_parser.conf"
  source = "${path.module}/files/conf/fluent-bit/nginx_access_log_parser.conf"

  etag = filemd5("${path.module}/files/conf/fluent-bit/nginx_access_log_parser.conf")
}

resource "aws_s3_object" "nginx_error_log_parser" {
  bucket = aws_s3_bucket.fluent_bit_config.bucket
  key    = "nginx_error_log_parser.conf"
  source = "${path.module}/files/conf/fluent-bit/nginx_error_log_parser.conf"

  etag = filemd5("${path.module}/files/conf/fluent-bit/nginx_error_log_parser.conf")
}

resource "aws_s3_bucket" "ecs_container_logs_web_app" {
  bucket        = "ecs-container-logs-web-app-${data.aws_caller_identity.current.account_id}"
  force_destroy = false
}

resource "aws_s3_bucket" "ecs_container_logs_web_server" {
  bucket        = "ecs-container-logs-web-server-${data.aws_caller_identity.current.account_id}"
  force_destroy = false
}

# AWS BatchのECSがFirelens対応された場合の将来設定（現在は利用していません）
resource "aws_s3_bucket" "ecs_container_logs_batch_default" {
  bucket        = "ecs-container-logs-batch-default-${data.aws_caller_identity.current.account_id}"
  force_destroy = false
}
