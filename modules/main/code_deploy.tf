resource "aws_codedeploy_app" "rails_web" {
  count = var.delete_before_ecs_task_update ? 0 : 1

  compute_platform = "ECS"
  name             = "rails-web"
}

resource "aws_codedeploy_deployment_group" "rails_web" {
  count = var.delete_before_ecs_task_update ? 0 : 1

  app_name               = aws_codedeploy_app.rails_web[0].name
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  deployment_group_name  = "rails-web"
  service_role_arn       = aws_iam_role.ecs_code_deploy.arn

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE", "DEPLOYMENT_STOP_ON_REQUEST"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }
    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 60
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.rails_web.name
    service_name = aws_ecs_service.rails_web[0].name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_lb_listener.rails_web_https.arn]
      }
      target_group {
        name = aws_lb_target_group.rails_web_b.name
      }
      target_group {
        name = aws_lb_target_group.rails_web_g.name
      }
      test_traffic_route {
        listener_arns = [aws_lb_listener.rails_web_test.arn]
      }
    }
  }
}
