resource "aws_batch_job_definition" "batch_default" {
  name = "batch-default"
  type = "container"

  platform_capabilities = ["FARGATE"]

  ecs_properties = templatefile(
    "${path.module}/files/json/job_definitions/batch_default.json.tpl",
    {
      execution_role_arn                      = aws_iam_role.ecs_task_execution.arn
      task_role_arn                           = aws_iam_role.batch_ecs_task.arn
      region                                  = data.aws_region.current.name
      container_name_batch                    = local.container_names.batch_default
      batch_image                             = "${aws_ecr_repository.batch_default.repository_url}:${local.latest_batch_default_tag}"
      cloudwatch_log_group_ecs_container_logs = aws_cloudwatch_log_group.ecs_container_logs.name
      vcpu                                    = var.ecs.task_definition.vcpu
      memory                                  = var.ecs.task_definition.memory
    }
  )

  lifecycle {
    ignore_changes = [
      ecs_properties
    ]
  }
}

resource "aws_batch_compute_environment" "batch_default" {
  compute_environment_name = "batch-default"

  type         = "MANAGED"
  service_role = aws_iam_role.batch_service.arn

  compute_resources {
    type      = "FARGATE"
    max_vcpus = 16
    subnets   = tolist(aws_subnet.privates[*].id)
    security_group_ids = [
      aws_security_group.batch.id
    ]
  }

  depends_on = [aws_iam_role_policy_attachment.batch_service]
}

resource "aws_batch_job_queue" "batch_default" {
  name     = "batch-default"
  state    = "ENABLED"
  priority = 1

  compute_environment_order {
    order               = 1
    compute_environment = aws_batch_compute_environment.batch_default.arn
  }
}

data "external" "latest_batch_default_tag" {
  program = [
    "aws", "ecr", "describe-images",
    "--repository-name", aws_ecr_repository.batch_default.name,
    "--no-paginate",
    "--query", "{\"tag\": to_string(sort_by(imageDetails[?imageTags != `null`], &imagePushedAt)[-1].imageTags[0])}"
  ]

  depends_on = [aws_ecr_repository.batch_default]
}

locals {
  latest_batch_default_tag = data.external.latest_batch_default_tag.result.tag != "null" ? data.external.latest_batch_default_tag.result.tag : "dummy"
}
