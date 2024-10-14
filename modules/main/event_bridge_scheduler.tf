locals {
  cloud_watch_logs_export_schedules = {
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

    ecs-task-stopped = {
      schedule           = "rate(${aws_cloudwatch_log_group.batch_job_status_changed.retention_in_days - 1} days)"
      log_group_name     = aws_cloudwatch_log_group.batch_job_status_changed.name
      destination_prefix = aws_cloudwatch_log_group.batch_job_status_changed.name
    }
  }

  batch_schedules = {
    example1 = {
      name        = "example-1"
      description = "This is example1"
      cron        = "cron(0 3 ? * 7 *)" # 毎週日曜日の1時
      job_command = "bundle exec rake test[hoge,fuga]"
      vcpu        = var.ecs.task_definition.vcpu
      memory      = var.ecs.task_definition.memory
    }

    example2 = {
      name        = "example-2"
      description = "This is example2"
      cron        = "cron(0 1 1 * ? *)" # 毎月1日の1時
      job_command = "bundle exec rake test[hoge,fuga,piyo]"
      vcpu        = var.ecs.task_definition.vcpu
      memory      = var.ecs.task_definition.memory
    }
  }
}

resource "aws_scheduler_schedule_group" "cloud_watch_logs_export" {
  name = "cloud-watch-logs-export"
}

resource "aws_scheduler_schedule_group" "batch_schedule" {
  name = "batch-schedule"
}

resource "aws_scheduler_schedule" "cloud_watch_logs_export" {
  for_each = local.cloud_watch_logs_export_schedules

  name       = "cloud-watch-logs-export-${each.key}"
  group_name = aws_scheduler_schedule_group.cloud_watch_logs_export.name
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

resource "aws_scheduler_schedule" "batch_schedule" {
  for_each = local.batch_schedules

  name        = "batch-schedule-${each.value.name}"
  group_name  = aws_scheduler_schedule_group.batch_schedule.name
  state       = var.service_suspend_mode ? "DISABLED" : "ENABLED"
  description = "${each.value.description}"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = "${each.value.cron}" # "cron(00 10 ? * 6 *)"
  schedule_expression_timezone = "Asia/Tokyo"

  target {
    # https://docs.aws.amazon.com/scheduler/latest/UserGuide/managing-targets-universal.html
    arn = "arn:aws:scheduler:::aws-sdk:batch:submitJob"
    role_arn = aws_iam_role.batch_schedule.arn

    input = templatefile(
      "${path.module}/files/json/event_bridge_target_input/batch_schedule.json.tpl",
      {
        job_name       = "${each.value.name}"
        job_definition = aws_batch_job_definition.batch_default.name
        job_queue      = aws_batch_job_queue.batch_default.name
        container_name = local.container_names.batch_default
        job_command    = "${each.value.job_command}" # "bundle exec rake test[hoge,fuga]"
        vcpu           = "${each.value.vcpu}" # var.ecs.task_definition.vcpu
        memory         = "${each.value.memory}" # var.ecs.task_definition.memory
      }
    )
  }
}
