variable "environment" {}
variable "app" {}
variable "profile" {}

variable "bouncr_proxy_repository" {
  description = "ECR repository for the bouncr proxy"
}

variable "bouncr_api_repository" {
  description = "ECR repository for the bouncr api"
}

variable "db_password" {
  default = "P3naJTDZ"
}
