# TODO: 削除予定
resource "aws_cloudwatch_log_group" "ecs_container" {
  name              = "ecs_container"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "firelens_fluent_bit" {
  name              = "/ecs/firelens/fluent-bit"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "ecs_container_errors" {
  name              = "/ecs/container-errors"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "firehose_errors" {
  name              = "/firehose/errors"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_stream" "ecs_firelens_firehose_s3" {
  name           = "ecs-firelens-firehose-s3"
  log_group_name = aws_cloudwatch_log_group.firehose_errors.name
}

resource "aws_cloudwatch_log_group" "rds" {
  name              = "/aws/rds/instance/${aws_db_instance.rds.identifier}/postgresql"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "ecs_task_stopped" {
  name              = "/aws/events/ecs/task-stopped"
  retention_in_days = 14
}
