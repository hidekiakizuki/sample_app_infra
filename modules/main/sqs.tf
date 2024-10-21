resource "aws_sqs_queue" "queue_default" {
  name = "queue-default"
  delay_seconds = 3 # producerによるキュー登録からDB更新コミットまでの時間を考慮します。
  receive_wait_time_seconds = 5 # 空キュー時にロングポーリングすることとします。
}

resource "aws_sqs_queue_redrive_policy" "queue_default" {
  queue_url = aws_sqs_queue.queue_default.id
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq_default.arn
    maxReceiveCount     = 4 # 4回より多く受信されたキューはDLQに移動します。
  })
}

resource "aws_sqs_queue" "dlq_default" {
  name = "dlq-default"
  message_retention_seconds = 60 * 60 * 24 * 14 # 14日間保持します。
  receive_wait_time_seconds = 20
}

resource "aws_sqs_queue_redrive_allow_policy" "dlq_default" {
  queue_url = aws_sqs_queue.dlq_default.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue",
    sourceQueueArns   = [aws_sqs_queue.queue_default.arn]
  })
}
