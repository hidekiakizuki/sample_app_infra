resource "aws_cloudwatch_log_group" "ecs_rails_web" {
  name              = var.app_name
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "rds" {
  name              = "/aws/rds/instance/${aws_db_instance.rds.identifier}/postgresql"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "ecs_task_stopped" {
  name              = "/aws/events/ecs/task_stopped"
  retention_in_days = 14
}