resource "aws_kinesis_firehose_delivery_stream" "ecs_container_logs_web_app" {
  name        = "ecs-container-logs-web-app"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose.arn
    bucket_arn = aws_s3_bucket.ecs_container_logs_web_app.arn

    buffering_size = 64 # 10秒間に取り込むデータ量（MB）を設定することが推奨されています。利用していませんが、動的パーティションニングに必要な64MBを確保しておきます。

    prefix              = "logs/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/"
    error_output_prefix = "errors/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/!{firehose:error-output-type}/"
    custom_time_zone    = "Asia/Tokyo"
    file_extension      = ".json"

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.firehose_errors.name
      log_stream_name = aws_cloudwatch_log_stream.ecs_web_app_firelens_firehose_s3.name # 必須
    }
  }
}

resource "aws_kinesis_firehose_delivery_stream" "ecs_container_logs_web_server" {
  name        = "ecs-container-logs-web-server"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose.arn
    bucket_arn = aws_s3_bucket.ecs_container_logs_web_server.arn

    buffering_size = 64 # 10秒間に取り込むデータ量（MB）を設定することが推奨されています。利用していませんが、動的パーティションニングに必要な64MBを確保しておきます。

    prefix              = "logs/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/"
    error_output_prefix = "errors/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/!{firehose:error-output-type}/"
    custom_time_zone    = "Asia/Tokyo"
    file_extension      = ".json"

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.firehose_errors.name
      log_stream_name = aws_cloudwatch_log_stream.ecs_web_server_firelens_firehose_s3.name # 必須
    }
  }
}
