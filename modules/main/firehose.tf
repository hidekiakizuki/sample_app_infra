resource "aws_kinesis_firehose_delivery_stream" "ecs_container_logs" {
  name        = "ecs-container-logs"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose.arn
    bucket_arn = aws_s3_bucket.ecs_container_logs.arn

    buffering_size = 64 # 動的パーティションニングは64MB以上が必要

    dynamic_partitioning_configuration {
      enabled = true
    }

    prefix              = "logs/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/level=!{partitionKeyFromQuery:level}/"
    error_output_prefix = "errors/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/!{firehose:error-output-type}/"
    custom_time_zone    = "Asia/Tokyo"
    file_extension      = ".json.gz"

    processing_configuration {
      enabled = true

      processors {
        type = "MetadataExtraction"
        parameters {
          parameter_name  = "JsonParsingEngine"
          parameter_value = "JQ-1.6"
        }
        parameters {
          parameter_name  = "MetadataExtractionQuery"
          parameter_value = "{level:.level}"
        }
      }
    }

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.firehose_errors.name # 必須
      log_stream_name = aws_cloudwatch_log_stream.ecs_firelens_firehose_s3.name # 必須
    }
  }
}
