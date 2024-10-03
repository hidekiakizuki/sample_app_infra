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

locals {
  event_bridge_schedules = {
    firelens = {
      schedule           = "rate(${aws_cloudwatch_log_group.firelens.retention_in_days - 1} days)"
      log_group_name     = aws_cloudwatch_log_group.firelens.name
      destination_prefix = aws_cloudwatch_log_group.firelens.name
    }

    firehose_errors = {
      schedule           = "rate(${aws_cloudwatch_log_group.firehose_errors.retention_in_days - 1} days)"
      log_group_name     = aws_cloudwatch_log_group.firehose_errors.name
      destination_prefix = aws_cloudwatch_log_group.firehose_errors.name
    }

    ecs_container_logs = {
      schedule           = "rate(${aws_cloudwatch_log_group.ecs_container_logs.retention_in_days - 1} days)"
      log_group_name     = aws_cloudwatch_log_group.ecs_container_logs.name
      destination_prefix = aws_cloudwatch_log_group.ecs_container_logs.name
    }

    rds = {
      schedule           = "rate(${aws_cloudwatch_log_group.rds.retention_in_days - 1} days)"
      log_group_name     = aws_cloudwatch_log_group.rds.name
      destination_prefix = aws_cloudwatch_log_group.rds.name
    }

    ecs-task-stopped = {
      schedule           = "rate(${aws_cloudwatch_log_group.ecs_task_stopped.retention_in_days - 1} days)"
      log_group_name     = aws_cloudwatch_log_group.ecs_task_stopped.name
      destination_prefix = aws_cloudwatch_log_group.ecs_task_stopped.name
    }
  }
}

resource "aws_scheduler_schedule" "cloud_watch_logs_export" {
  for_each = local.event_bridge_schedules

  name       = "cloud-watch-logs-export-${each.key}"
  group_name = "default"
  state      = var.service_suspend_mode ? "DISABLED" : "ENABLED"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = each.value.schedule
  schedule_expression_timezone = "Asia/Tokyo"

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:cloudwatchlogs:createExportTask"
    role_arn = aws_iam_role.cloud_watch_logs_export.arn

    input = templatefile(
      "${path.module}/files/json/event_bridge_target_input/cloud_watch_logs_export.json.tpl",
      {
        log_group_name     = each.value.log_group_name
        destination        = aws_s3_bucket.cloud_watch_logs_backups.bucket
        destination_prefix = each.value.destination_prefix
      }
    )
  }
}