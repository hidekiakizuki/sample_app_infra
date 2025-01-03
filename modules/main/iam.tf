resource "aws_iam_role" "ecs_task" {
  name               = "ecs-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ecs_task" {
  role       = aws_iam_role.ecs_task.name
  policy_arn = aws_iam_policy.ecs_task.arn
}

resource "aws_iam_policy" "ecs_task" {
  name   = "ecs-task"
  policy = data.aws_iam_policy_document.ecs_task.json
}

data "aws_iam_policy_document" "ecs_task" {
  statement {
    effect = "Allow"
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetBucketLocation"
    ]
    resources = [
      aws_s3_bucket.fluent_bit_config.arn,
      "${aws_s3_bucket.fluent_bit_config.arn}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "sqs:GetQueueUrl",
      "sqs:SendMessage",
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:DeleteMessageBatch",
      "sqs:ChangeMessageVisibility"
    ]
    resources = [
      aws_sqs_queue.default.arn,
      aws_sqs_queue.dlq_default.arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "firehose:PutRecordBatch"
    ]
    resources = [
      aws_kinesis_firehose_delivery_stream.ecs_container_logs_web_app.arn,
      aws_kinesis_firehose_delivery_stream.ecs_container_logs_web_server.arn,
      aws_kinesis_firehose_delivery_stream.ecs_container_logs_worker.arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents"
    ]
    resources = [
      "${aws_cloudwatch_log_group.firelens.arn}:log-stream:*",
      "${aws_cloudwatch_log_group.ecs_container_error_logs.arn}:log-stream:*"
    ]
  }

  version = "2012-10-17"
}

data "aws_iam_policy_document" "ecs_tasks_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }

  version = "2012-10-17"
}

resource "aws_iam_role" "batch_ecs_task" {
  name               = "batch-ecs-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role.json
}

resource "aws_iam_role_policy_attachment" "batch_ecs_task1" {
  role       = aws_iam_role.batch_ecs_task.name
  policy_arn = aws_iam_policy.ecs_task.arn
}

resource "aws_iam_role_policy_attachment" "batch_ecs_task2" {
  role       = aws_iam_role.batch_ecs_task.name
  policy_arn = aws_iam_policy.batch_ecs_task.arn
}

resource "aws_iam_policy" "batch_ecs_task" {
  name   = "batch-ecs-task"
  policy = data.aws_iam_policy_document.batch_ecs_task.json
}

data "aws_iam_policy_document" "batch_ecs_task" {
  statement {
    effect = "Allow"
    actions = [
      "firehose:PutRecordBatch"
    ]
    resources = [
      aws_kinesis_firehose_delivery_stream.ecs_container_logs_batch_default.arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents"
    ]
    resources = ["${aws_cloudwatch_log_group.ecs_container_logs.arn}:log-stream:*"]
  }

  version = "2012-10-17"
}

resource "aws_iam_role" "ecs_task_execution" {
  name               = "ecs-task-execution"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution1" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution2" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = aws_iam_policy.parameter_store_secrets_manager_read.arn
}

resource "aws_iam_policy" "parameter_store_secrets_manager_read" {
  name   = "parameter-store-secrets-manager-read"
  policy = data.aws_iam_policy_document.parameter_store_secrets_manager_read.json
}

data "aws_iam_policy_document" "parameter_store_secrets_manager_read" {
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameters"
    ]
    resources = [
      "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/app/*",
      "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/elasticache/*",
      "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/rds/*",
      "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/sqs/*"
    ]
  }

  version = "2012-10-17"
}

resource "aws_iam_role" "firehose" {
  name               = "firehose"
  assume_role_policy = data.aws_iam_policy_document.firehose_assume_role.json
}

resource "aws_iam_role_policy_attachment" "firehose" {
  role       = aws_iam_role.firehose.name
  policy_arn = aws_iam_policy.firehose.arn
}

resource "aws_iam_policy" "firehose" {
  name   = "firehose"
  policy = data.aws_iam_policy_document.firehose.json
}

data "aws_iam_policy_document" "firehose" {
  statement {
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject"
    ]
    resources = [
      aws_s3_bucket.ecs_container_logs_web_app.arn,
      "${aws_s3_bucket.ecs_container_logs_web_app.arn}/*",
      aws_s3_bucket.ecs_container_logs_web_server.arn,
      "${aws_s3_bucket.ecs_container_logs_web_server.arn}/*",
      aws_s3_bucket.ecs_container_logs_worker.arn,
      "${aws_s3_bucket.ecs_container_logs_worker.arn}/*",
      aws_s3_bucket.ecs_container_logs_batch_default.arn,
      "${aws_s3_bucket.ecs_container_logs_batch_default.arn}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:PutLogEvents"
    ]
    resources = [
      "${aws_cloudwatch_log_group.firehose_errors.arn}:log-stream:*"
    ]
  }

  version = "2012-10-17"
}

data "aws_iam_policy_document" "firehose_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }

  version = "2012-10-17"
}

resource "aws_iam_role" "ecs_code_deploy" {
  name               = "ecs-code-deploy"
  assume_role_policy = data.aws_iam_policy_document.ecs_code_deploy_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ecs_code_deploy" {
  role       = aws_iam_role.ecs_code_deploy.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}

data "aws_iam_policy_document" "ecs_code_deploy_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }

  version = "2012-10-17"
}

resource "aws_iam_role" "batch_service" {
  name               = "batch-service"
  assume_role_policy = data.aws_iam_policy_document.batch_service_assume_role.json
}

resource "aws_iam_role_policy_attachment" "batch_service" {
  role       = aws_iam_role.batch_service.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}

data "aws_iam_policy_document" "batch_service_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["batch.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }

  version = "2012-10-17"
}

resource "aws_iam_role" "batch_schedule" {
  name               = "batch-schedule"
  assume_role_policy = data.aws_iam_policy_document.batch_schedule_assume_role.json
}

resource "aws_iam_role_policy_attachment" "batch_schedule" {
  role       = aws_iam_role.batch_schedule.name
  policy_arn = aws_iam_policy.batch_schedule.arn
}

resource "aws_iam_policy" "batch_schedule" {
  name   = "batch-schedule"
  policy = data.aws_iam_policy_document.batch_schedule.json
}

data "aws_iam_policy_document" "batch_schedule" {
  statement {
    effect = "Allow"
    actions = [
      "batch:DescribeJobs",
      "batch:SubmitJob",
      "batch:TerminateJob"
    ]
    resources = [
      "arn:aws:batch:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:job-definition/*",
      "arn:aws:batch:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:job-queue/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "events:DescribeRule",
      "events:PutRule",
      "events:PutTargets"
    ]
    resources = [
      "*"
    ]
  }

  version = "2012-10-17"
}

data "aws_iam_policy_document" "batch_schedule_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }

  version = "2012-10-17"
}

resource "aws_iam_role" "rds_monitoring" {
  name               = "rds-monitoring"
  assume_role_policy = data.aws_iam_policy_document.monitoring_rds_assume_role.json
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

data "aws_iam_policy_document" "monitoring_rds_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }

  version = "2012-10-17"
}

resource "aws_iam_role" "git_hub_actions_oidc" {
  name               = "git-hub-actions-oidc"
  assume_role_policy = data.aws_iam_policy_document.github_actions_oidc_assume_role.json
}

resource "aws_iam_role_policy_attachment" "git_hub_actions_oidc" {
  role       = aws_iam_role.git_hub_actions_oidc.name
  policy_arn = aws_iam_policy.git_hub_actions_deploy.arn
}

resource "aws_iam_policy" "git_hub_actions_deploy" {
  name   = "git-hub-actions-deploy"
  policy = data.aws_iam_policy_document.git_hub_actions_deploy.json
}

data "aws_iam_policy_document" "git_hub_actions_deploy" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
      "ecr:ListImages",
      "ecr:CompleteLayerUpload",
      "ecr:BatchCheckLayerAvailability"
    ]
    resources = ["arn:aws:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecs:DescribeServices",
      "ecs:UpdateService"
    ]
    resources = ["arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:service/*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "codedeploy:ListDeployments",
      "codedeploy:GetDeploymentGroup",
      "codedeploy:CreateDeployment",
      "codedeploy:GetDeployment",
      "codedeploy:GetDeploymentConfig",
      "codedeploy:RegisterApplicationRevision"
    ]
    resources = ["arn:aws:codedeploy:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "iam:PassRole",
    ]
    resources = [
      aws_iam_role.ecs_task.arn,
      aws_iam_role.ecs_task_execution.arn,
      aws_iam_role.batch_ecs_task.arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecs:DescribeTaskDefinition",
      "ecs:RegisterTaskDefinition"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "batch:DescribeJobDefinitions",
      "batch:RegisterJobDefinition",
      "batch:TagResource"
    ]
    resources = ["*"]
  }

  version = "2012-10-17"
}

data "aws_iam_policy_document" "github_actions_oidc_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [var.app_repository]
    }
  }

  version = "2012-10-17"
}

data "aws_iam_policy_document" "sns_topic" {
  statement {
    sid    = "sns"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "SNS:AddPermission",
      "SNS:DeleteTopic",
      "SNS:GetTopicAttributes",
      "SNS:ListSubscriptionsByTopic",
      "SNS:Publish",
      "SNS:RemovePermission",
      "SNS:Subscribe",
      "SNS:SetTopicAttributes"
    ]

    resources = ["arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  statement {
    sid    = "event_bridge"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    actions = ["sns:Publish"]

    resources = ["arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]
  }

  version = "2012-10-17"
}

resource "aws_iam_role" "cloud_watch_logs_export" {
  name               = "cloud-watch-logs-export"
  assume_role_policy = data.aws_iam_policy_document.scheduler_assume_role.json
}

resource "aws_iam_role_policy_attachment" "cloud_watch_logs_export1" {
  role       = aws_iam_role.cloud_watch_logs_export.name
  policy_arn = aws_iam_policy.cloud_watch_logs_export.arn
}

resource "aws_iam_role_policy_attachment" "cloud_watch_logs_export2" {
  role       = aws_iam_role.cloud_watch_logs_export.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_policy" "cloud_watch_logs_export" {
  name   = "cloud-watch-logs-export"
  policy = data.aws_iam_policy_document.cloud_watch_logs_export.json
}

data "aws_iam_policy_document" "cloud_watch_logs_export" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateExportTask",
      "logs:CancelExportTask",
      "logs:DescribeExportTasks",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]
    resources = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:*"]
  }

  version = "2012-10-17"
}

data "aws_iam_policy_document" "scheduler_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }

  version = "2012-10-17"
}
