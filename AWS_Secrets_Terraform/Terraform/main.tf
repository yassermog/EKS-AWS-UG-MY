############################### Terrafrom Setup ###############################
terraform {
  backend "s3" {
    bucket = "aws-usg-my-eks-pres"
    key    = ".tfstate2"
    region = "ap-southeast-1"
  }
}

provider "aws" {
  region = var.region
}
############################### END Setup ###############################

############################### Set Password ############################
resource "random_password" "password" {
  keepers = {
    uuid = uuid()
  }
  length           = 16
  special          = false
  min_lower        = 1
  min_numeric      = 1
  min_upper        = 1
  number           = true
  upper            = true
  override_special = "\"'_%@/ "
}


resource "aws_secretsmanager_secret" "vault" {
  name = var.secret_name
}

resource "aws_secretsmanager_secret_version" "example" {
  secret_id = aws_secretsmanager_secret.vault.id
  //secret_string = random_password.password.result
  secret_string = <<EOF
  {
    "username": "${aws_db_instance.test_db.username}",
    "password": "${random_password.password.result}",
    "engine": "mysql",
    "host": "${aws_db_instance.test_db.endpoint}",
    "port": "${aws_db_instance.test_db.port}",
    "dbname": "${aws_db_instance.test_db.identifier}",
    "dbInstanceIdentifier": "${aws_db_instance.test_db.identifier}"
  }
  EOF
}

##############################################################################
resource "aws_db_instance" "test_db" {
  name                   = var.db_identifier
  identifier             = var.db_identifier
  instance_class         = "db.t2.micro"
  allocated_storage      = 10
  engine                 = "mysql"
  username               = var.db_username
  password               = random_password.password.result
  publicly_accessible    = true
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.allow_myip.id,aws_security_group.allow_lambda.id]
}

# Get My IP
module myip {
  source  = "4ops/myip/http"
  version = "1.0.0"
}

resource aws_security_group allow_myip {
  name        = "allow_myip"
  description = "Allow myip inbound connections"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["${module.myip.address}/32"]
  }
}
resource aws_security_group allow_lambda {
  name        = "allow_lambda"
  description = "Allow lambda inbound connections"

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    #security_groups = [var.lambda_subnsecurity_group_id]
    cidr_blocks = ["0.0.0.0/0"]
  }
}

