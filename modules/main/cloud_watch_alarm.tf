resource "aws_cloudwatch_metric_alarm" "rails_web_alarm_high" {
  count = var.delete_before_ecs_task_update ? 0 : 1

  alarm_name          = "TargetTracking-service/${aws_ecs_cluster.rails_web.name}/${aws_ecs_service.rails_web[0].name}-AlarmHigh"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 70
  unit                = "Percent"

  dimensions = {
    ClusterName = aws_ecs_cluster.rails_web.name
    ServiceName = aws_ecs_service.rails_web[0].name
  }

  alarm_description = "DO NOT EDIT OR DELETE. For TargetTrackingScaling policy ${aws_appautoscaling_policy.rails_web[0].arn}."
  actions_enabled   = true
  alarm_actions     = [aws_appautoscaling_policy.rails_web[0].arn, aws_sns_topic.alert.arn]
  ok_actions        = [aws_sns_topic.alert.arn]
}

resource "aws_cloudwatch_metric_alarm" "rails_web_alarm_low" {
  count = var.delete_before_ecs_task_update ? 0 : 1

  alarm_name          = "TargetTracking-service/${aws_ecs_cluster.rails_web.name}/${aws_ecs_service.rails_web[0].name}-AlarmLow"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 15
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 63
  unit                = "Percent"

  dimensions = {
    ClusterName = aws_ecs_cluster.rails_web.name
    ServiceName = aws_ecs_service.rails_web[0].name
  }

  alarm_description = "DO NOT EDIT OR DELETE. For TargetTrackingScaling policy ${aws_appautoscaling_policy.rails_web[0].arn}."
  actions_enabled   = true
  alarm_actions     = [aws_appautoscaling_policy.rails_web[0].arn]
}
