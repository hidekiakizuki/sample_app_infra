resource "aws_cloudwatch_event_rule" "ecs_task_stopped" {
  name          = "ecs-task-stopped"
  event_pattern = file("${path.module}/files/json/event_pattern/ecs_task_stopped.json")
}

resource "aws_cloudwatch_event_target" "ecs_task_stopped" {
  target_id  = "ecs_task_stopped"
  rule       = "ecs-task-stopped"
  arn        = aws_sns_topic.warn.arn
  depends_on = [aws_cloudwatch_event_rule.ecs_task_stopped]
}
