[
  {
    "name": "${container_name_worker}",
    "image": "${worker_image}",
    "essential": true,
    "command": ["bundle", "exec", "aws_sqs_active_job", "--queue", "default"],
    "dependsOn": [
      { "containerName": "${container_name_log_router}", "condition": "HEALTHY" }
    ],
    "dockerLabels": {
      "Name": "${container_name_worker}"
    },
    "secrets": [
      {
        "name": "POSTGRES_DB",
        "valueFrom": "/rds/postgres/database"
      },
      {
        "name": "POSTGRES_HOST",
        "valueFrom": "/rds/postgres/host"
      },
      {
        "name": "POSTGRES_USER",
        "valueFrom": "/rds/postgres/user"
      },
      {
        "name": "POSTGRES_PASSWORD",
        "valueFrom": "/rds/postgres/password"
      },
      {
        "name": "SECRET_KEY_BASE",
        "valueFrom": "/app/rails/secret_key_base"
      },
      {
        "name": "SQS_QUEUE_DEFAULT",
        "valueFrom": "/sqs/queue/default"
      }
    ],
    "logConfiguration": {
      "logDriver": "awsfirelens"
    }
  },
  {
    "name": "${container_name_log_router}",
    "image": "${log_router_image}",
    "essential": true,
    "dockerLabels": {
      "Name": "${container_name_log_router}"
    },
    "environment": [
        {
          "name": "CONTAINER_NAME_WORKER",
          "value": "${container_name_worker}"
        },
        {
          "name": "CLOUD_WATCH_LOG_GROUP_ECS_CONTAINER_ERROR_LOGS",
          "value": "${cloudwatch_log_group_ecs_container_error_logs}"
        },
        {
          "name": "FIREHOSE_DELIVERY_STREAM_WORKER",
          "value": "${firehose_delivery_stream_worker}"
        },
        {
          "name": "aws_fluent_bit_init_s3_1",
          "value": "${worker_extra_conf}"
        },
        {
          "name": "aws_fluent_bit_init_s3_2",
          "value": "${rails_log_parser_conf}"
        }
    ],
    "healthCheck": {
      "retries": 3,
      "command": [
        "CMD-SHELL",
        "curl -f http://127.0.0.1:2020/api/v1/uptime || exit 1"
      ],
      "timeout": 5,
      "interval": 10,
      "startPeriod": 30
    },
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-region": "${region}",
        "awslogs-group": "${cloudwatch_log_group_firelens}",
        "awslogs-stream-prefix": "worker",
        "awslogs-create-group": "true"
      }
    },
    "firelensConfiguration": {
      "type": "fluentbit"
    },
    "memoryReservation": 50
  }
]
