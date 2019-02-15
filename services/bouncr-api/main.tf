resource "aws_cloudwatch_log_group" "bouncr_api" {
  name              = "bouncr-api"
  retention_in_days = 1
}

resource "aws_ecs_task_definition" "bouncr_api" {
  family                   = "bouncr-api"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = "${var.role_ecsTaskExecutionRole_arn}"

  #  task_role_arn = "${aws_iam_role.app_role.arn}"

  container_definitions = <<EOF
[
  {
    "name": "bouncr-api",
    "image": "${var.ecr_repository}",
    "portMappings": [
      {
        "containerPort": 3005,
        "hostPort": 3005
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-region": "ap-northeast-1",
        "awslogs-group": "bouncr-api",
        "awslogs-stream-prefix": "bouncr-api"
      }
    },
    "environment": [
      {
        "name": "JDBC_URL",
        "value": "${var.jdbc_url}"
      },
      {
        "name": "JDBC_USER",
        "value": "${var.jdbc_user}"
      },
      {
        "name": "JDBC_PASSWORD",
        "value": "${var.jdbc_password}"
      },
      {
        "name": "REDIS_HOST",
        "value": "${var.redis_host}"
      },
      {
        "name": "REDIS_PORT",
        "value": "${var.redis_port}"
      },
      {
        "name": "API_BACKEND_URL",
        "value": "http://bouncr-api.dev.bouncr:3005/bouncr/api"
      }
    ]
  }
]
EOF
}

resource "aws_ecs_service" "bouncr_api" {
  name            = "bouncr-api"
  cluster         = "${var.cluster_id}"
  launch_type     = "FARGATE"
  task_definition = "${aws_ecs_task_definition.bouncr_api.arn}"

  desired_count = 1

  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0

  network_configuration {
    security_groups  = ["${var.security_groups}"]
    subnets          = ["${var.subnets}"]
  }

  service_registries {
    registry_arn = "${var.registry_arn}"
  }
}
