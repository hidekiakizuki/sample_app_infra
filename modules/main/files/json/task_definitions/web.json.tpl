[
  {
    "name": "${container_name_web_app}",
    "image": "${web_app_image}",
    "essential": true,
    "command": ["bundle", "exec", "puma", "-C", "config/puma.rb"],
    "dependsOn": [
      { "containerName": "${container_name_log_router}", "condition": "HEALTHY" }
    ],
    "dockerLabels": {
      "Name": "${container_name_web_app}"
    },
    "portMappings": [
      {
        "name": "${container_name_web_app}-3000-tcp",
        "appProtocol": "http",
        "containerPort": 3000,
        "hostPort": 3000,
        "protocol": "tcp"
      }
    ],
    "healthCheck": {
      "retries": 3,
      "command": [
        "CMD-SHELL",
        "curl -f http://localhost:3000/healthy || exit 1"
      ],
      "timeout": 5,
      "interval": 10,
      "startPeriod": 30
    },
    "mountPoints": [
      {
        "sourceVolume": "public",
        "containerPath": "/${app_name}/public",
        "readOnly": false
      },
      {
        "sourceVolume": "tmp",
        "containerPath": "/${app_name}/tmp",
        "readOnly": false
      }
    ],
    "secrets": [
      {
        "name": "ELASTICACHE_HOST",
        "valueFrom": "/elasticache/default/host"
      },
      {
        "name": "ELASTICACHE_USER",
        "valueFrom": "/elasticache/default-custom/user"
      },
      {
        "name": "ELASTICACHE_PASSWORD",
        "valueFrom": "/elasticache/default-custom/password"
      },
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
    "name": "${container_name_web_server}",
    "image": "${web_server_image}",
    "essential": true,
    "dependsOn": [
      { "containerName": "${container_name_log_router}", "condition": "HEALTHY" },
      { "containerName": "${container_name_web_app}",  "condition": "HEALTHY"   }
    ],
    "dockerLabels": {
      "Name": "${container_name_web_server}"
    },
    "portMappings": [
      {
        "name": "${container_name_web_server}-80-tcp",
        "appProtocol": "http",
        "containerPort": 80,
        "hostPort": 80,
        "protocol": "tcp"
      }
    ],
    "healthCheck": {
      "retries": 3,
      "command": [
        "CMD-SHELL",
        "curl -f http://localhost:80/healthy || exit 1"
      ],
      "timeout": 5,
      "interval": 10,
      "startPeriod": 30
    },
    "mountPoints": [
      {
        "sourceVolume": "public",
        "containerPath": "/${app_name}/public",
        "readOnly": true
      },
      {
        "sourceVolume": "tmp",
        "containerPath": "/${app_name}/tmp",
        "readOnly": true
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
          "name": "CONTAINER_NAME_WEB_APP",
          "value": "${container_name_web_app}"
        },
        {
          "name": "CONTAINER_NAME_WEB_SERVER",
          "value": "${container_name_web_server}"
        },
        {
          "name": "CLOUD_WATCH_LOG_GROUP_ECS_CONTAINER_ERROR_LOGS",
          "value": "${cloudwatch_log_group_ecs_container_error_logs}"
        },
        {
          "name": "FIREHOSE_DELIVERY_STREAM_WEB_APP",
          "value": "${firehose_delivery_stream_web_app}"
        },
        {
          "name": "FIREHOSE_DELIVERY_STREAM_WEB_SERVER",
          "value": "${firehose_delivery_stream_web_server}"
        },
        {
          "name": "aws_fluent_bit_init_s3_1",
          "value": "${web_extra_conf}"
        },
        {
          "name": "aws_fluent_bit_init_s3_2",
          "value": "${rails_log_parser_conf}"
        },
        {
          "name": "aws_fluent_bit_init_s3_3",
          "value": "${nginx_access_log_parser_conf}"
        },
        {
          "name": "aws_fluent_bit_init_s3_4",
          "value": "${nginx_error_log_parser_conf}"
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
        "awslogs-stream-prefix": "web",
        "awslogs-create-group": "true"
      }
    },
    "firelensConfiguration": {
      "type": "fluentbit"
    },
    "memoryReservation": 50
  }
]
