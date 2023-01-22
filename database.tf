
################################################################################
# CREATING MYSQL DATABASE
################################################################################

resource "random_password" "password" {
  length  = 16
  special = false
}

resource "aws_secretsmanager_secret" "this" {
  name_prefix = "${var.component_name}-"
  description = "Secret to manage superuser ${var.username} password"
}

resource "aws_secretsmanager_secret_version" "registration_app" {
  secret_id     = aws_secretsmanager_secret.this.id
  secret_string = jsonencode(local.db_secret)
}

locals {
  db_secret = {
    endpoint = aws_db_instance.registration_app_db.address
    dbname   = var.db_name
    username = var.username
    password = random_password.password.result
    port     = var.port
  }
}

resource "aws_db_subnet_group" "subnet_group" {
  name       = "${var.component_name}-subnet-group"
  subnet_ids = local.private_subnet
}

resource "aws_security_group" "registration-database-sg" {
  name        = "${var.component_name}-database-sg"
  description = "Allow registration app on port ${var.port}"
  vpc_id      = local.vpc_id

  tags = {
    Name = "${var.component_name}-database-sg"
  }
}

resource "aws_security_group_rule" "db-security_ingress_access_on_http" {

  security_group_id        = aws_security_group.registration-database-sg.id
  type                     = "ingress"
  from_port                = var.port
  to_port                  = var.port
  protocol                 = "tcp"
  source_security_group_id = local.eks_cluster_security_group
}

resource "aws_db_instance" "registration_app_db" {

  allocated_storage      = 10
  db_name                = var.db_name
  port                   = var.port
  engine                 = "mysql"
  instance_class         = var.instance_class
  username               = var.username
  password               = random_password.password.result
  db_subnet_group_name   = aws_db_subnet_group.subnet_group.name
  skip_final_snapshot    = true
  multi_az               = false
  vpc_security_group_ids = [aws_security_group.registration-database-sg.id]
}
