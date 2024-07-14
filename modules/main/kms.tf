resource "aws_kms_key" "rds" {
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.kms_rds.json

  tags = {
    Name = "rds"
  }
}

resource "aws_kms_alias" "rds" {
  name          = "alias/rds/postgres"
  target_key_id = aws_kms_key.rds.key_id
}

data "aws_iam_policy_document" "kms_rds" {
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
