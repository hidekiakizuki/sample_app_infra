resource "aws_sns_topic" "notification" {
  name = "notification"
}

resource "aws_sns_topic_policy" "notification" {
  arn = aws_sns_topic.notification.arn
  policy = data.aws_iam_policy_document.sns_topic.json
}

resource "aws_sns_topic" "alert" {
  name = "alert"
}

resource "aws_sns_topic_policy" "alert" {
  arn = aws_sns_topic.alert.arn
  policy = data.aws_iam_policy_document.sns_topic.json
}
