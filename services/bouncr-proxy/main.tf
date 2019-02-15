resource "aws_cloudwatch_log_group" "bouncr-proxy" {
  name              = "bouncr-proxy"
  retention_in_days = 1
}

resource "aws_ecs_task_definition" "bouncr_proxy" {
  family                   = "bouncr-proxy"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = "${var.role_ecsTaskExecutionRole_arn}"

  #  task_role_arn = "${aws_iam_role.app_role.arn}"

  container_definitions = <<EOF
[
  {
    "name": "bouncr-proxy",
    "image": "${var.ecr_repository}",
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-region": "ap-northeast-1",
        "awslogs-group": "bouncr-proxy",
        "awslogs-stream-prefix": "bouncr-proxy"
      }
    },
    "portMappings": [
      {
        "containerPort": 3000,
        "hostPort": 3000
      }
    ],
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
      }
    ]
  }
]
EOF
}

resource "aws_ecs_service" "bouncr_proxy" {
  name            = "bouncr-proxy"
  cluster         = "${var.cluster_id}"
  launch_type     = "FARGATE"
  task_definition = "${aws_ecs_task_definition.bouncr_proxy.arn}"

  desired_count = 1

  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0

  network_configuration {
    assign_public_ip = "true"
    security_groups  = ["${var.security_groups}"]
    subnets          = ["${var.subnets}"]
  }

  load_balancer {
    target_group_arn = "${var.target_group_arn}"
    container_name   = "bouncr-proxy"
    container_port   = "${var.proxy_port}"
  }
}
