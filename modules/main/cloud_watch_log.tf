resource "aws_cloudwatch_log_group" "ecs_rails_web" {
  name              = var.app_name
  retention_in_days = 14
}