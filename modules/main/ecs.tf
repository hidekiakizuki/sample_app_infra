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
  desired_count   = var.service_suspend_mode ? 0 : var.ecs.service.desired_count

  launch_type         = "FARGATE"
  platform_version    = var.ecs.service.platform_version
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
    security_groups  = [aws_security_group.ecs.id]
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
  min_capacity       = var.appautoscaling_target.min_capacity
  max_capacity       = var.appautoscaling_target.max_capacity
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
  cpu                      = var.ecs.task_definition.cpu
  memory                   = var.ecs.task_definition.memory

  container_definitions = templatefile(
    "${path.module}/files/json/task_definitions/web.json.tpl",
    {
      app_name                                      = var.app_name
      region                                        = data.aws_region.current.name
      container_name_web_app                        = local.container_names.web_app
      container_name_web_server                     = local.container_names.web_server
      container_name_log_router                     = local.container_names.log_router
      web_app_image                                 = "${aws_ecr_repository.web_app.repository_url}:dummy"
      web_server_image                              = "${aws_ecr_repository.web_server.repository_url}:dummy"
      log_router_image                              = "public.ecr.aws/aws-observability/aws-for-fluent-bit:init-latest"
      cloudwatch_log_group_ecs_container_error_logs = aws_cloudwatch_log_group.ecs_container_error_logs.name
      firehose_delivery_stream_web_app              = aws_kinesis_firehose_delivery_stream.ecs_container_logs_web_app.name
      firehose_delivery_stream_web_server           = aws_kinesis_firehose_delivery_stream.ecs_container_logs_web_server.name
      web_extra_conf                                = aws_s3_object.web_extra.arn
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
