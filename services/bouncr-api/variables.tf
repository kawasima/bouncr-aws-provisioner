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

variable "role_ecsTaskExecutionRole_arn" {
  type    = "string"
}

variable "registry_arn" {
  description = "The ARN of the service registry"
  type = "string"
}

variable "ecr_repository" {}

variable "jdbc_url" {}

variable "jdbc_user" {}

variable "jdbc_password" {}

variable "redis_host" {}

variable "redis_port" {}
