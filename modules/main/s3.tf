resource "aws_s3_bucket" "terraform_state" {
  bucket        = "terraform-state-${data.aws_caller_identity.current.account_id}"
  force_destroy = false
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket                = aws_s3_bucket.terraform_state.bucket

  versioning_configuration {
    status     = "Enabled"
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

