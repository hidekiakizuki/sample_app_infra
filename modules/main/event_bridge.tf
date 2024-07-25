resource "aws_cloudwatch_event_rule" "ecs_task_stopped" {
  name          = "ecs-task-stopped"
  event_pattern = file("${path.module}/files/json/event_pattern/ecs_task_stopped.json")
}

resource "aws_cloudwatch_event_target" "ecs_task_stopped_to_sns" {
  target_id  = "ecs_task_stopped_to_sns"
  rule       = "ecs-task-stopped"
  arn        = aws_sns_topic.error.arn
  depends_on = [aws_cloudwatch_event_rule.ecs_task_stopped]
}

resource "aws_cloudwatch_event_target" "ecs_task_stopped_to_cloud_watch_logs" {
  target_id  = "ecs_task_stopped_to_cloud_watch_logs"
  rule       = "ecs-task-stopped"
  arn        = aws_cloudwatch_log_group.ecs_task_stopped.arn
  depends_on = [aws_cloudwatch_event_rule.ecs_task_stopped]
}
