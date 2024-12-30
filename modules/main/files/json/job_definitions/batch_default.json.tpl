{
  "taskProperties": [
    {
      "executionRoleArn": "${execution_role_arn}",
      "taskRoleArn": "${task_role_arn}",
      "containers": [
        {
          "name": "${container_name_batch}",
          "image": "${batch_image}",
          "essential": true,
          "resourceRequirements": [
            {
              "type": "VCPU",
              "value": "${vcpu}"
            },
            {
              "type": "MEMORY",
              "value": "${memory}"
            }
          ],
          "environment": [
            {
              "name": "ENABLE_SYNC_STDOUT",
              "value": "true"
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
            "logDriver": "awslogs",
            "options": {
              "awslogs-region": "${region}",
              "awslogs-group": "${cloudwatch_log_group_ecs_container_logs}",
              "awslogs-stream-prefix": "batch-default",
              "awslogs-create-group": "true"
            }
          }
        }
      ]
    }
  ]
}
