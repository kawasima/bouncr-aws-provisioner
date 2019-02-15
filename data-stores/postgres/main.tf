resource "aws_db_instance" "postgres" {
  engine            = "postgres"
  engine_version    = "10.4"
  storage_type      = "gp2"
  allocated_storage = 20
  instance_class    = "db.t2.micro"
  name              = "db_${var.environment}"
  username          = "${replace(var.db_username, "/\\-/", "_")}"
  password          = "${var.db_password}"

  db_subnet_group_name = "${aws_db_subnet_group.postgres.name}"
  vpc_security_group_ids = ["${var.security_groups}"]
}

resource "aws_db_subnet_group" "postgres" {
  name = "posgres-subnet"
  subnet_ids = ["${var.subnets}"]
}

output "address" {
  value = "${aws_db_instance.postgres.address}"
}

output "port" {
  value = "${aws_db_instance.postgres.port}"
}

output "username" {
  value = "${aws_db_instance.postgres.username}"
}

output "name" {
  value = "${aws_db_instance.postgres.name}"
}
