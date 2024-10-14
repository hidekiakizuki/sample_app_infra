resource "aws_cloudwatch_event_rule" "ecs_task_stopped" {
  name          = "ecs-task-stopped"
  event_pattern = file("${path.module}/files/json/event_bridge_event_pattern/ecs_task_stopped.json")
}

resource "aws_cloudwatch_event_target" "ecs_task_stopped_to_sns" {
  target_id  = "ecs_task_stopped_to_sns"
  rule       = aws_cloudwatch_event_rule.ecs_task_stopped.name
  arn        = aws_sns_topic.error.arn
  depends_on = [aws_cloudwatch_event_rule.ecs_task_stopped]
}

resource "aws_cloudwatch_event_target" "ecs_task_stopped_to_cloud_watch_logs" {
  target_id  = "ecs_task_stopped_to_cloud_watch_logs"
  rule       = aws_cloudwatch_event_rule.ecs_task_stopped.name
  arn        = aws_cloudwatch_log_group.ecs_task_stopped.arn
  depends_on = [aws_cloudwatch_event_rule.ecs_task_stopped]
}

resource "aws_cloudwatch_event_rule" "batch_job_status_changed" {
  name          = "batch-job-status-changed"
  event_pattern = file("${path.module}/files/json/event_bridge_event_pattern/batch_job_status_changed.json")
}

resource "aws_cloudwatch_event_target" "batch_job_status_changed_to_sns" {
  target_id  = "batch_job_status_changed_to_sns"
  rule       = aws_cloudwatch_event_rule.batch_job_status_changed.name
  arn        = aws_sns_topic.batch.arn
  depends_on = [aws_cloudwatch_event_rule.batch_job_status_changed]
}

resource "aws_cloudwatch_event_target" "batch_job_status_changed_to_cloud_watch_logs" {
  target_id  = "batch_job_status_changed_to_cloud_watch_logs"
  rule       = aws_cloudwatch_event_rule.batch_job_status_changed.name
  arn        = aws_cloudwatch_log_group.batch_job_status_changed.arn
  depends_on = [aws_cloudwatch_event_rule.batch_job_status_changed]
}
