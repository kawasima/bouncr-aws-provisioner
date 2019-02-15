provider "aws" {
  profile = "${var.profile}"
  region  = "ap-northeast-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.2.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Environment = "${var.environment}"
  }
}

resource "aws_subnet" "front_1" {
  vpc_id = "${aws_vpc.main.id}"
  cidr_block = "10.2.1.0/24"
  availability_zone = "ap-northeast-1a"
}
resource "aws_subnet" "front_2" {
  vpc_id = "${aws_vpc.main.id}"
  cidr_block = "10.2.2.0/24"
  availability_zone = "ap-northeast-1c"
}
resource "aws_subnet" "front_3" {
  vpc_id = "${aws_vpc.main.id}"
  cidr_block = "10.2.3.0/24"
  availability_zone = "ap-northeast-1d"
}
resource "aws_subnet" "back_1" {
  vpc_id = "${aws_vpc.main.id}"
  cidr_block = "10.2.101.0/24"
  availability_zone = "ap-northeast-1a"
}
resource "aws_subnet" "back_2" {
  vpc_id = "${aws_vpc.main.id}"
  cidr_block = "10.2.102.0/24"
  availability_zone = "ap-northeast-1c"
}
resource "aws_subnet" "back_3" {
  vpc_id = "${aws_vpc.main.id}"
  cidr_block = "10.2.103.0/24"
  availability_zone = "ap-northeast-1d"
}

resource "aws_internet_gateway" "public" {
  vpc_id = "${aws_vpc.main.id}"
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.public.id}"
  }
}

resource "aws_route_table_association" "public_1" {
  route_table_id = "${aws_route_table.public.id}"
  subnet_id      = "${aws_subnet.front_1.id}"
}

resource "aws_route_table_association" "public_2" {
  route_table_id = "${aws_route_table.public.id}"
  subnet_id      = "${aws_subnet.front_2.id}"
}

resource "aws_route_table_association" "public_3" {
  route_table_id = "${aws_route_table.public.id}"
  subnet_id      = "${aws_subnet.front_3.id}"
}

resource "aws_lb" "front_end" {
  name               = "bouncr-alb"
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.alb_sg.id}"]
  subnets            = ["${aws_subnet.front_1.id}", "${aws_subnet.front_2.id}", "${aws_subnet.front_3.id}"]
}

resource "aws_lb_target_group" "front_end" {
  name        = "front-end-lb-tg"
  port        = 3000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = "${aws_vpc.main.id}"

  health_check {
    path = "/"
    matcher = "404"
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = "${aws_lb.front_end.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.front_end.arn}"
  }
}

resource "aws_vpc_endpoint" "ecs" {
  vpc_id       = "${aws_vpc.main.id}"
  vpc_endpoint_type = "Interface"
  service_name = "com.amazonaws.ap-northeast-1.ecr.dkr"
  security_group_ids = ["${aws_security_group.database_sg.id}"]
  subnet_ids = ["${aws_subnet.back_1.id}", "${aws_subnet.back_2.id}", "${aws_subnet.back_3.id}"]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id       = "${aws_vpc.main.id}"
  vpc_endpoint_type = "Interface"
  service_name = "com.amazonaws.ap-northeast-1.logs"
  security_group_ids = ["${aws_security_group.database_sg.id}"]
  subnet_ids = ["${aws_subnet.back_1.id}", "${aws_subnet.back_2.id}", "${aws_subnet.back_3.id}"]
  private_dns_enabled = true
}


# Security Group
resource "aws_security_group" "alb_sg" {
  name   = "alb_sg"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port  = 0
    to_port    = 0
    protocol   = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "bouncr_proxy_sg" {
  name   = "bouncr_proxy_sg"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = ["${aws_security_group.alb_sg.id}"]
  }

  egress {
    from_port  = 0
    to_port    = 0
    protocol   = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "bouncr_api_sg" {
  name   = "bouncr_api_sg"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = ["${aws_security_group.bouncr_proxy_sg.id}"]
  }
  egress {
    from_port  = 0
    to_port    = 0
    protocol   = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "database_sg" {
  name   = "database_sg"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"

    security_groups = [
      "${aws_security_group.bouncr_proxy_sg.id}",
      "${aws_security_group.bouncr_api_sg.id}",
    ]
  }
  egress {
    from_port  = 0
    to_port    = 0
    protocol   = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_service_discovery_private_dns_namespace" "bouncr_internal" {
  name = "${var.environment}.bouncr"
  vpc      = "${aws_vpc.main.id}"
}

resource "aws_service_discovery_service" "bouncr_internal" {
  name = "bouncr-internal"

  dns_config {
    namespace_id = "${aws_service_discovery_private_dns_namespace.bouncr_internal.id}"

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }
}

module "database" {
  app         = "${var.app}"
  environment = "${var.environment}"
  source      = "data-stores/postgres"

  db_username     = "${var.app}"
  db_password     = "${var.db_password}"
  subnets         = ["${aws_subnet.back_1.id}", "${aws_subnet.back_2.id}", "${aws_subnet.back_3.id}"]
  security_groups = ["${aws_security_group.database_sg.id}"]
}

module "cache" {
  app         = "${var.app}"
  environment = "${var.environment}"
  source      = "data-stores/redis"

  subnets         = ["${aws_subnet.back_1.id}", "${aws_subnet.back_2.id}", "${aws_subnet.back_3.id}"]
  security_groups = ["${aws_security_group.database_sg.id}"]
}

# ECS
resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "${var.app}-${var.environment}-ecs"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role_policy.json}"
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = "${aws_iam_role.ecsTaskExecutionRole.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_cluster" "front_end" {
  name = "${var.app}-${var.environment}-frontend"
}

resource "aws_ecs_cluster" "back_end" {
  name = "${var.app}-${var.environment}-backend"
}

module "bouncr-proxy" {
  app         = "${var.app}"
  environment = "${var.environment}"

  source           = "services/bouncr-proxy"
  cluster_id       = "${aws_ecs_cluster.front_end.id}"
  security_groups  = ["${aws_security_group.bouncr_proxy_sg.id}"]
  subnets          = ["${aws_subnet.front_1.id}", "${aws_subnet.front_2.id}", "${aws_subnet.front_3.id}"]
  role_ecsTaskExecutionRole_arn = "${aws_iam_role.ecsTaskExecutionRole.arn}"
  target_group_arn = "${aws_lb_target_group.front_end.arn}"
  ecr_repository   = "${var.bouncr_proxy_repository}"

  jdbc_url      = "jdbc:postgresql://${module.database.address}/${module.database.name}"
  jdbc_user     = "${module.database.username}"
  jdbc_password = "${var.db_password}"

  redis_host = "${module.cache.host}"
  redis_port = "${module.cache.port}"
}

module "bouncr-api" {
  app         = "${var.app}"
  environment = "${var.environment}"

  source           = "services/bouncr-api"
  cluster_id       = "${aws_ecs_cluster.back_end.id}"
  security_groups  = ["${aws_security_group.bouncr_api_sg.id}"]
  subnets          = ["${aws_subnet.back_1.id}", "${aws_subnet.back_2.id}", "${aws_subnet.back_3.id}"]
  ecr_repository   = "${var.bouncr_api_repository}"
  role_ecsTaskExecutionRole_arn = "${aws_iam_role.ecsTaskExecutionRole.arn}"
  registry_arn     = "${aws_service_discovery_service.bouncr_internal.arn}"

  jdbc_url      = "jdbc:postgresql://${module.database.address}/${module.database.name}"
  jdbc_user     = "${module.database.username}"
  jdbc_password = "${var.db_password}"

  redis_host = "${module.cache.host}"
  redis_port = "${module.cache.port}"
}
