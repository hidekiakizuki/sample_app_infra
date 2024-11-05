### Web ############################################################################################################
resource "aws_ecs_cluster" "web" {
  name = "web"

  configuration {
    execute_command_configuration {
      logging = "DEFAULT"
    }
  }

  service_connect_defaults {
    namespace = aws_service_discovery_http_namespace.web.arn
  }

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_service_discovery_http_namespace" "web" {
  name = "web"

  tags = {
    AmazonECSManaged = "true"
  }
}

resource "aws_ecs_service" "web" {
  count = var.delete_before_ecs_task_update ? 0 : 1

  name = "web"

  cluster         = aws_ecs_cluster.web.id
  task_definition = aws_ecs_task_definition.web.arn
  desired_count   = var.service_suspend_mode ? 0 : var.ecs["web"].service.desired_count

  launch_type         = "FARGATE"
  platform_version    = var.ecs["web"].service.platform_version
  scheduling_strategy = "REPLICA"

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  health_check_grace_period_seconds  = 300

  enable_execute_command = true

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  load_balancer {
    target_group_arn = local.current_https_target_group_arn
    container_name   = local.container_names.web_server
    container_port   = 80
  }

  network_configuration {
    subnets          = tolist(aws_subnet.publics[*].id)
    security_groups  = [aws_security_group.web.id]
    assign_public_ip = true
  }

  lifecycle {
    ignore_changes = [
      task_definition,
      load_balancer
    ]
  }
}

resource "aws_appautoscaling_target" "web" {
  count = var.delete_before_ecs_task_update ? 0 : 1

  resource_id = "service/${aws_ecs_cluster.web.name}/${aws_ecs_service.web[0].name}"
  role_arn    = data.aws_iam_role.appautoscaling_ecs.arn

  service_namespace  = "ecs"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.appautoscaling_target["web"].min_capacity
  max_capacity       = var.appautoscaling_target["web"].max_capacity
}

data "aws_iam_role" "appautoscaling_ecs" {
  name = "AWSServiceRoleForApplicationAutoScaling_ECSService"
}

resource "aws_appautoscaling_policy" "web" {
  count = var.delete_before_ecs_task_update ? 0 : 1

  name        = "web"
  resource_id = aws_appautoscaling_target.web[0].resource_id

  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.web[0].service_namespace
  scalable_dimension = aws_appautoscaling_target.web[0].scalable_dimension

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value       = 70
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}

resource "aws_ecs_task_definition" "web" {
  family = "web"

  execution_role_arn = aws_iam_role.ecs_task_execution.arn
  task_role_arn      = aws_iam_role.ecs_task.arn

  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.ecs["web"].task_definition.cpu
  memory                   = var.ecs["web"].task_definition.memory

  container_definitions = templatefile(
    "${path.module}/files/json/task_definitions/web.json.tpl",
    {
      app_name                                      = var.app_name
      region                                        = data.aws_region.current.name
      container_name_web_app                        = local.container_names.web_app
      container_name_web_server                     = local.container_names.web_server
      container_name_log_router                     = local.container_names.log_router
      web_app_image                                 = "${aws_ecr_repository.main.repository_url}:${local.ecr_main_latest_tag}"
      web_server_image                              = "${aws_ecr_repository.web_server.repository_url}:${local.ecr_web_server_latest_tag}"
      # 特定のバージョンではSIGSEGVを受信しコンテナが落ちることがありました。将来的にイメージのバージョンアップで再びコンテナが落ちることもありえるためバージョンを固定します。
      log_router_image                              = "public.ecr.aws/aws-observability/aws-for-fluent-bit:init-amd64-2.32.2.20241003"
      cloudwatch_log_group_ecs_container_error_logs = aws_cloudwatch_log_group.ecs_container_error_logs.name
      firehose_delivery_stream_web_app              = aws_kinesis_firehose_delivery_stream.ecs_container_logs_web_app.name
      firehose_delivery_stream_web_server           = aws_kinesis_firehose_delivery_stream.ecs_container_logs_web_server.name
      web_extra_conf                                = aws_s3_object.web_extra.arn
      rails_log_parser_conf                         = aws_s3_object.rails_log_parser.arn
      nginx_access_log_parser_conf                  = aws_s3_object.nginx_access_log_parser.arn
      nginx_error_log_parser_conf                   = aws_s3_object.nginx_error_log_parser.arn
      cloudwatch_log_group_firelens                 = aws_cloudwatch_log_group.firelens.name
    }
  )
  track_latest = true

  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }

  volume {
    name = "public"
  }

  volume {
    name = "tmp"
  }

  lifecycle {
    ignore_changes = all
  }
}


### Worker #########################################################################################################
resource "aws_ecs_cluster" "worker" {
  name = "worker"

  configuration {
    execute_command_configuration {
      logging = "DEFAULT"
    }
  }

  service_connect_defaults {
    namespace = aws_service_discovery_http_namespace.worker.arn
  }

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_service_discovery_http_namespace" "worker" {
  name = "worker"

  tags = {
    AmazonECSManaged = "true"
  }
}

resource "aws_ecs_service" "worker" {
  count = var.delete_before_ecs_task_update ? 0 : 1

  name = "worker"

  cluster         = aws_ecs_cluster.worker.id
  task_definition = aws_ecs_task_definition.worker.arn
  desired_count   = var.service_suspend_mode ? 0 : var.ecs["worker"].service.desired_count

  launch_type         = "FARGATE"
  platform_version    = var.ecs["worker"].service.platform_version
  scheduling_strategy = "REPLICA"

  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0
  health_check_grace_period_seconds  = 300

  enable_execute_command = true

  deployment_controller {
    type = "ECS"
  }

  network_configuration {
    subnets          = tolist(aws_subnet.privates[*].id)
    security_groups  = [aws_security_group.worker.id]
  }

  lifecycle {
    ignore_changes = [
      task_definition
    ]
  }
}

resource "aws_appautoscaling_target" "worker" {
  count = var.delete_before_ecs_task_update ? 0 : 1

  resource_id = "service/${aws_ecs_cluster.worker.name}/${aws_ecs_service.worker[0].name}"
  role_arn    = data.aws_iam_role.appautoscaling_ecs.arn

  service_namespace  = "ecs"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.appautoscaling_target["worker"].min_capacity
  max_capacity       = var.appautoscaling_target["worker"].max_capacity
}

resource "aws_appautoscaling_policy" "worker" {
  count = var.delete_before_ecs_task_update ? 0 : 1

  name        = "worker"
  resource_id = aws_appautoscaling_target.worker[0].resource_id

  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.worker[0].service_namespace
  scalable_dimension = aws_appautoscaling_target.worker[0].scalable_dimension

  target_tracking_scaling_policy_configuration {
    target_value = 100 # 1タスクあたり100件のメッセージを処理することを目指します。

    customized_metric_specification {
      metrics {
        label = "Get the queue size (the number of messages waiting to be processed)"
        id    = "m1"

        metric_stat {
          metric {
            metric_name = "ApproximateNumberOfMessagesVisible"
            namespace   = "AWS/SQS"

            dimensions {
              name  = "QueueName"
              value = aws_sqs_queue.default.name
            }
          }

          stat = "Sum"
        }

        return_data = false
      }

      metrics {
        label = "Get the ECS running task count (the number of currently running tasks)"
        id    = "m2"

        metric_stat {
          metric {
            metric_name = "RunningTaskCount"
            namespace   = "ECS/ContainerInsights"

            dimensions {
              name  = "ClusterName"
              value = aws_ecs_cluster.worker.name
            }

            dimensions {
              name  = "ServiceName"
              value = aws_ecs_service.worker[0].name
            }
          }

          stat = "Average"
        }

        return_data = false
      }

      metrics {
        label       = "Calculate the backlog per instance"
        id          = "e1"
        expression  = "m1 / m2"
        return_data = true
      }
    }
  }
}

resource "aws_ecs_task_definition" "worker" {
  family = "worker"

  execution_role_arn = aws_iam_role.ecs_task_execution.arn
  task_role_arn      = aws_iam_role.ecs_task.arn

  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.ecs["worker"].task_definition.cpu
  memory                   = var.ecs["worker"].task_definition.memory

  container_definitions = templatefile(
    "${path.module}/files/json/task_definitions/worker.json.tpl",
    {
      region                                        = data.aws_region.current.name
      container_name_worker                         = local.container_names.worker
      container_name_log_router                     = local.container_names.log_router
      worker_image                                  = "${aws_ecr_repository.main.repository_url}:${local.ecr_main_latest_tag}"
      # 特定のバージョンではSIGSEGVを受信しコンテナが落ちることがありました。将来的にイメージのバージョンアップで再びコンテナが落ちることもありえるためバージョンを固定します。
      log_router_image                              = "public.ecr.aws/aws-observability/aws-for-fluent-bit:init-amd64-2.32.2.20241003"
      cloudwatch_log_group_ecs_container_error_logs = aws_cloudwatch_log_group.ecs_container_error_logs.name
      firehose_delivery_stream_worker               = aws_kinesis_firehose_delivery_stream.ecs_container_logs_worker.name
      worker_extra_conf                             = aws_s3_object.worker_extra.arn
      rails_log_parser_conf                         = aws_s3_object.rails_log_parser.arn
      cloudwatch_log_group_firelens                 = aws_cloudwatch_log_group.firelens.name
    }
  )
  track_latest = true

  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }

  lifecycle {
    ignore_changes = all
  }
}
