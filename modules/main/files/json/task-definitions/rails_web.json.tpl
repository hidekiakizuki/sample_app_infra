[
  {
    "name": "rails-web",
    "image": "${rails_web_image}",
    "essential": true,
    "dockerLabels": {
      "Name": "rails-web"
    },
    "portMappings": [
      {
        "name": "rails-web-3000-tcp",
        "appProtocol": "http",
        "containerPort": 3000,
        "hostPort": 3000,
        "protocol": "tcp"
      }
    ],
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
        "awslogs-group": "${app_name}",
        "awslogs-stream-prefix": "ecs/rails_web",
        "awslogs-create-group": "true"
      }
    }
  },
  {
    "name": "nginx",
    "image": "${nginx_image}",
    "essential": true,
    "dependsOn": [
      {
        "condition": "START",
        "containerName": "rails-web"
      }
    ],
    "dockerLabels": {
      "Name": "nginx"
    },
    "portMappings": [
      {
        "name": "nginx-80-tcp",
        "appProtocol": "http",
        "containerPort": 80,
        "hostPort": 80,
        "protocol": "tcp"
      }
    ],
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
      "logDriver": "awslogs",
      "options": {
        "awslogs-region": "${region}",
        "awslogs-group": "${app_name}",
        "awslogs-stream-prefix": "ecs/nginx",
        "awslogs-create-group": "true"
      }
    }
  }
]
