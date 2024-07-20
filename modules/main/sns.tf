resource "aws_sns_topic" "info" {
  name = "info"
}

resource "aws_sns_topic_policy" "info" {
  arn    = aws_sns_topic.info.arn
  policy = data.aws_iam_policy_document.sns_topic.json
}

resource "aws_sns_topic" "warn" {
  name = "warn"
}

resource "aws_sns_topic_policy" "warn" {
  arn    = aws_sns_topic.warn.arn
  policy = data.aws_iam_policy_document.sns_topic.json
}

resource "aws_sns_topic" "error" {
  name = "error"
}

resource "aws_sns_topic_policy" "error" {
  arn    = aws_sns_topic.error.arn
  policy = data.aws_iam_policy_document.sns_topic.json
}

resource "aws_sns_topic_subscription" "chatbot_info" {
  topic_arn = aws_sns_topic.info.arn
  protocol  = "https"
  endpoint  = "https://global.sns-api.chatbot.amazonaws.com"
}

resource "aws_sns_topic_subscription" "chatbot_warn" {
  topic_arn = aws_sns_topic.warn.arn
  protocol  = "https"
  endpoint  = "https://global.sns-api.chatbot.amazonaws.com"
}

resource "aws_sns_topic_subscription" "chatbot_error" {
  topic_arn = aws_sns_topic.error.arn
  protocol  = "https"
  endpoint  = "https://global.sns-api.chatbot.amazonaws.com"
}

resource "aws_sns_topic_subscription" "mail_info" {
  topic_arn = aws_sns_topic.info.arn
  protocol  = "email"
  endpoint  = var.sns_subscription_email
}

resource "aws_sns_topic_subscription" "mail_warn" {
  topic_arn = aws_sns_topic.warn.arn
  protocol  = "email"
  endpoint  = var.sns_subscription_email
}

resource "aws_sns_topic_subscription" "mail_error" {
  topic_arn = aws_sns_topic.error.arn
  protocol  = "email"
  endpoint  = var.sns_subscription_email
}
