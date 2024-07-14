resource "aws_ecs_cluster" "rails_web" {
  name = "rails-web"

  configuration {
    execute_command_configuration {
      logging    = "DEFAULT"
    }
  }

  service_connect_defaults {
    namespace = aws_service_discovery_http_namespace.rails_web.arn
  }

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_service_discovery_http_namespace" "rails_web" {
  name        = "rails-web"

  tags = {
    AmazonECSManaged = "true"
  }
}

resource "aws_ecs_service" "rails_web" {
  count = var.delete_before_ecs_task_update ? 0 : 1

  name                               = "rails-web"

  cluster                            = aws_ecs_cluster.rails_web.id
  task_definition                    = aws_ecs_task_definition.rails_web.arn
  desired_count                      = var.ecs.service.desired_count

  launch_type                        = "FARGATE"
  platform_version                   = var.ecs.service.platform_version
  scheduling_strategy                = "REPLICA"

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  health_check_grace_period_seconds  = 300

  enable_execute_command             = true

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  load_balancer {
    target_group_arn = local.current_https_target_group_arn
    container_name   = "nginx"
    container_port   = 80
  }

  network_configuration {
    subnets          = tolist(aws_subnet.publics[*].id)
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = true
  }

  lifecycle {
    ignore_changes = [
      task_definition
    ]
  }
}

resource "aws_appautoscaling_target" "rails_web" {
  count = var.delete_before_ecs_task_update ? 0 : 1

  resource_id        = "service/${aws_ecs_cluster.rails_web.name}/${aws_ecs_service.rails_web[0].name}"
  role_arn           = data.aws_iam_role.appautoscaling_ecs.arn

  service_namespace  = "ecs"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = var.appautoscaling_target.min_capacity
  max_capacity       = var.appautoscaling_target.max_capacity
}

data "aws_iam_role" "appautoscaling_ecs" {
  name = "AWSServiceRoleForApplicationAutoScaling_ECSService"
}

resource "aws_appautoscaling_policy" "rails_web" {
  count = var.delete_before_ecs_task_update ? 0 : 1

  name               = "rails-web"
  resource_id        = aws_appautoscaling_target.rails_web[0].resource_id

  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.rails_web[0].service_namespace
  scalable_dimension = aws_appautoscaling_target.rails_web[0].scalable_dimension

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value       = 70
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}

resource "aws_ecs_task_definition" "rails_web" {
  family                   = "rails-web"

  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.ecs.task_definition.cpu
  memory                   = var.ecs.task_definition.memory

  container_definitions    = templatefile(
    "${path.module}/files/json/task-definitions/rails_web.json.tpl",
    {
      app_name            = var.app_name
      region              = data.aws_region.current.name
      nginx_image       = "${aws_ecr_repository.nginx.repository_url}:dummy"
      rails_web_image   = "${aws_ecr_repository.rails_web.repository_url}:dummy"
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
