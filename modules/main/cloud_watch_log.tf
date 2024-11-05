resource "aws_cloudwatch_log_group" "firelens" {
  name              = "/ecs/container/firelens"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "ecs_container_error_logs" {
  name              = "/ecs/container/error-logs"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "firehose_errors" {
  name              = "/firehose/errors"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_stream" "ecs_web_app_firelens_firehose_s3" {
  name           = "ecs-web-app-firelens-firehose-s3"
  log_group_name = aws_cloudwatch_log_group.firehose_errors.name
}

resource "aws_cloudwatch_log_stream" "ecs_web_server_firelens_firehose_s3" {
  name           = "ecs-web-server-firelens-firehose-s3"
  log_group_name = aws_cloudwatch_log_group.firehose_errors.name
}

resource "aws_cloudwatch_log_stream" "ecs_worker_firelens_firehose_s3" {
  name           = "ecs-worker-firelens-firehose-s3"
  log_group_name = aws_cloudwatch_log_group.firehose_errors.name
}

# AWS BatchのECSがFirelens対応された場合の将来設定（現在は利用していません）
resource "aws_cloudwatch_log_stream" "ecs_batch_default_fluentd_firehose_s3" {
  name           = "ecs-batch-default-fluentd-firehose-s3"
  log_group_name = aws_cloudwatch_log_group.firehose_errors.name
}

# AWS BatchのECSがFirelens対応されるまでの暫定設定
resource "aws_cloudwatch_log_group" "ecs_container_logs" {
  name              = "/ecs/container/logs"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "rds" {
  name              = "/aws/rds/instance/${aws_db_instance.rds.identifier}/postgresql"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "ecs_task_stopped" {
  name              = "/aws/events/ecs/task-stopped"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "batch_job_status_changed" {
  name              = "/aws/events/batch/job-status-changed"
  retention_in_days = 14
}
