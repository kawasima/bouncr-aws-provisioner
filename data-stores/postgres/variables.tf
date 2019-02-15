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

variable "db_username" {
  description = "The username for the database"
}

variable "db_password" {
  description = "The password for the database"
}
