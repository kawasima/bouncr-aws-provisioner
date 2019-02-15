variable "environment" {}
variable "app" {}

variable "cluster_id" {
  description = "The ECS cluster ID"
}

variable "subnets" {
  type    = "list"
  default = []
}

variable "security_groups" {
  type    = "list"
  default = []
}

variable "target_group_arn" {
  type = "string"
}

variable "role_ecsTaskExecutionRole_arn" {
  type    = "string"
}


variable "proxy_port" {
  default = 3000
}

variable "ecr_repository" {}

variable "jdbc_url" {}

variable "jdbc_user" {}

variable "jdbc_password" {}

variable "redis_host" {}

variable "redis_port" {}
