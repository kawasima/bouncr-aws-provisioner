resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "redis-${var.environment}"
  engine               = "redis"
  node_type            = "cache.t2.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis5.0"
  engine_version       = "5.0.0"
  subnet_group_name    = "${aws_elasticache_subnet_group.redis_subnet.name}"
  security_group_ids   = ["${var.security_groups}"]
}

resource "aws_elasticache_subnet_group" "redis_subnet" {
  name       = "redis-subnet"
  subnet_ids = ["${var.subnets}"]
}

output "host" {
  value = "${aws_elasticache_cluster.redis.cache_nodes.0.address}"
}

output "port" {
  value = "${aws_elasticache_cluster.redis.cache_nodes.0.port}"
}
