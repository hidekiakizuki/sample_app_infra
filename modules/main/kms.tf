resource "aws_kms_key" "rds" {
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.kms.json

  tags = {
    Name = "rds"
  }
}

resource "aws_kms_key" "elasticache" {
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.kms.json

  tags = {
    Name = "elasticache"
  }
}

data "aws_iam_policy_document" "kms" {
  statement {
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  version = "2012-10-17"
}
