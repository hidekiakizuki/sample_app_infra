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
          "command": ["bash", "-c", "bundle exec rake test"],
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
