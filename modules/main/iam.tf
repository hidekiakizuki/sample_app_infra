
resource "aws_iam_role" "ecs_task" {
  name                 = "ecs-task"
  managed_policy_arns  = [aws_iam_policy.ssm_session_manager_access.arn]
  assume_role_policy   = data.aws_iam_policy_document.ecs_tasks_assume_role.json
  max_session_duration = 3600
}

resource "aws_iam_policy" "ssm_session_manager_access" {
  name   = "ssm-session-manager-access"
  policy = data.aws_iam_policy_document.ssm_session_manager_access.json
}

data "aws_iam_policy_document" "ssm_session_manager_access" {
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

resource "aws_iam_role" "ecs_task_execution" {
  name = "ecs-task-execution"
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
    aws_iam_policy.parameter_store_secrets_manager_read.arn
  ]
  assume_role_policy   = data.aws_iam_policy_document.ecs_tasks_assume_role.json
  max_session_duration = 3600
}

resource "aws_iam_policy" "parameter_store_secrets_manager_read" {
  name   = "parameter-store-secrets-manager-read"
  policy = data.aws_iam_policy_document.parameter_store_secrets_manager_read.json
}

data "aws_iam_policy_document" "parameter_store_secrets_manager_read" {
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameters",
      "secretsmanager:GetSecretValue",
      "kms:Decrypt"
    ]
    resources = ["*"]
  }

  version = "2012-10-17"
}

resource "aws_iam_role" "ecs" {
  name                 = "ecs"
  managed_policy_arns  = [aws_iam_policy.ecs_management.arn]
  assume_role_policy   = data.aws_iam_policy_document.ecs_assume_role.json
  max_session_duration = 3600
}

resource "aws_iam_policy" "ecs_management" {
  name   = "ecs-management"
  policy = data.aws_iam_policy_document.ecs_management.json
}

data "aws_iam_policy_document" "ecs_management" {
  statement {
    sid    = "ECSTaskManagement"
    effect = "Allow"
    actions = [
      "ec2:AttachNetworkInterface",
      "ec2:CreateNetworkInterface",
      "ec2:CreateNetworkInterfacePermission",
      "ec2:DeleteNetworkInterface",
      "ec2:DeleteNetworkInterfacePermission",
      "ec2:Describe*",
      "ec2:DetachNetworkInterface",
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:Describe*",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "elasticloadbalancing:RegisterTargets",
      "route53:ChangeResourceRecordSets",
      "route53:CreateHealthCheck",
      "route53:DeleteHealthCheck",
      "route53:Get*",
      "route53:List*",
      "route53:UpdateHealthCheck",
      "servicediscovery:DeregisterInstance",
      "servicediscovery:Get*",
      "servicediscovery:List*",
      "servicediscovery:RegisterInstance",
      "servicediscovery:UpdateInstanceCustomHealthStatus"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AutoScaling"
    effect = "Allow"
    actions = [
      "autoscaling:Describe*"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AutoScalingManagement"
    effect = "Allow"
    actions = [
      "autoscaling:DeletePolicy",
      "autoscaling:PutScalingPolicy",
      "autoscaling:SetInstanceProtection",
      "autoscaling:UpdateAutoScalingGroup",
      "autoscaling:PutLifecycleHook",
      "autoscaling:DeleteLifecycleHook",
      "autoscaling:CompleteLifecycleAction",
      "autoscaling:RecordLifecycleActionHeartbeat"
    ]
    resources = ["*"]

    condition {
      test     = "Null"
      variable = "autoscaling:ResourceTag/AmazonECSManaged"
      values   = ["false"]
    }
  }

  statement {
    sid    = "AutoScalingPlanManagement"
    effect = "Allow"
    actions = [
      "autoscaling-plans:CreateScalingPlan",
      "autoscaling-plans:DeleteScalingPlan",
      "autoscaling-plans:DescribeScalingPlans",
      "autoscaling-plans:DescribeScalingPlanResources",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "EventBridge"
    effect = "Allow"
    actions = [
      "events:DescribeRule",
      "events:ListTargetsByRule",
    ]
    resources = ["arn:aws:events:*:*:rule/ecs-managed-*"]
  }

  statement {
    sid    = "EventBridgeRuleManagement"
    effect = "Allow"
    actions = [
      "events:PutRule",
      "events:PutTargets",
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "events:ManagedBy"
      values   = ["ecs.amazonaws.com"]
    }
  }

  statement {
    sid    = "CWAlarmManagement"
    effect = "Allow"
    actions = [
      "cloudwatch:DeleteAlarms",
      "cloudwatch:DescribeAlarms",
      "cloudwatch:PutMetricAlarm",
    ]
    resources = ["arn:aws:cloudwatch:*:*:alarm:*"]
  }

  statement {
    sid       = "ECSTagging"
    effect    = "Allow"
    actions   = ["ec2:CreateTags"]
    resources = ["arn:aws:ec2:*:*:network-interface/*"]
  }

  statement {
    sid    = "CWLogGroupManagement"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:DescribeLogGroups",
      "logs:PutRetentionPolicy",
    ]
    resources = ["arn:aws:logs:*:*:log-group:/aws/ecs/*"]
  }

  statement {
    sid    = "CWLogStreamManagement"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
    ]
    resources = ["arn:aws:logs:*:*:log-group:/aws/ecs/*:log-stream:*"]
  }

  statement {
    sid       = "ExecuteCommandSessionManagement"
    effect    = "Allow"
    actions   = ["ssm:DescribeSessions"]
    resources = ["*"]
  }

  statement {
    sid     = "ExecuteCommand"
    effect  = "Allow"
    actions = ["ssm:StartSession"]
    resources = [
      "arn:aws:ecs:*:*:task/*",
      "arn:aws:ssm:*:*:document/AmazonECS-ExecuteInteractiveCommand",
    ]
  }

  statement {
    sid    = "CloudMapResourceCreation"
    effect = "Allow"
    actions = [
      "servicediscovery:CreateHttpNamespace",
      "servicediscovery:CreateService",
    ]
    resources = ["*"]

    condition {
      test     = "ForAllValues:StringEquals"
      variable = "aws:TagKeys"
      values   = ["AmazonECSManaged"]
    }
  }

  statement {
    sid       = "CloudMapResourceTagging"
    effect    = "Allow"
    actions   = ["servicediscovery:TagResource"]
    resources = ["*"]

    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/AmazonECSManaged"
      values   = ["*"]
    }
  }

  statement {
    sid       = "CloudMapResourceDeletion"
    effect    = "Allow"
    actions   = ["servicediscovery:DeleteService"]
    resources = ["*"]

    condition {
      test     = "Null"
      variable = "aws:ResourceTag/AmazonECSManaged"
      values   = ["false"]
    }
  }

  statement {
    sid    = "CloudMapResourceDiscovery"
    effect = "Allow"
    actions = [
      "servicediscovery:DiscoverInstances",
      "servicediscovery:DiscoverInstancesRevision",
    ]
    resources = ["*"]
  }

  version = "2012-10-17"
}

data "aws_iam_policy_document" "ecs_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }

  version = "2012-10-17"
}

resource "aws_iam_role" "ecs_code_deploy" {
  name                 = "ecs-code-deploy"
  managed_policy_arns  = ["arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"]
  assume_role_policy   = data.aws_iam_policy_document.ecs_code_deploy_assume_role.json
  max_session_duration = 3600
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

resource "aws_iam_role" "rds_monitoring" {
  name                 = "rds-monitoring"
  managed_policy_arns  = ["arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"]
  assume_role_policy   = data.aws_iam_policy_document.monitoring_rds_assume_role.json
  max_session_duration = 3600
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
  name                 = "git-hub-actions-oidc"
  managed_policy_arns  = [aws_iam_policy.git_hub_actions_deploy.arn]
  assume_role_policy   = data.aws_iam_policy_document.github_actions_oidc_assume_role.json
  max_session_duration = 3600

}

resource "aws_iam_policy" "git_hub_actions_deploy" {
  name   = "git-hub-actions-deploy"
  policy = data.aws_iam_policy_document.git_hub_actions_deploy.json
}

data "aws_iam_policy_document" "git_hub_actions_deploy" {
  statement {
    sid    = "ecr"
    effect = "Allow"
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
      "ecr:ListImages",
      "ecr:CompleteLayerUpload",
      "ecr:BatchCheckLayerAvailability",
    ]
    resources = ["arn:aws:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/*"]
  }

  statement {
    sid    = "ecs"
    effect = "Allow"
    actions = [
      "ecs:DescribeServices",
    ]
    resources = ["arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:service/*"]
  }

  statement {
    sid    = "codedeploy"
    effect = "Allow"
    actions = [
      "codedeploy:ListDeployments",
      "codedeploy:GetDeploymentGroup",
      "codedeploy:CreateDeployment",
      "codedeploy:GetDeployment",
      "codedeploy:GetDeploymentConfig",
      "codedeploy:RegisterApplicationRevision",
    ]
    resources = ["arn:aws:codedeploy:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]
  }

  statement {
    sid    = "iam"
    effect = "Allow"
    actions = [
      "iam:PassRole",
    ]
    resources = [
      aws_iam_role.ecs_task.arn,
      aws_iam_role.ecs_task_execution.arn
    ]
  }

  statement {
    sid    = "other"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecs:DescribeTaskDefinition",
      "ecs:RegisterTaskDefinition",
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

    resources = ["*"]

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

    resources = ["*"]
  }

  version = "2012-10-17"
}

resource "aws_iam_role" "cloud_watch_logs_export" {
  name                 = "cloud-watch-logs-export"
  managed_policy_arns  = [aws_iam_policy.cloud_watch_logs_export.arn, "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"]
  assume_role_policy   = data.aws_iam_policy_document.scheduler_assume_role.json
  max_session_duration = 3600
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
    resources = ["*"]
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
