variable "environment" {}
variable "app" {}

variable "subnets" {
  type    = "list"
  default = []
}

variable "security_groups" {
  type    = "list"
  default = []
}
