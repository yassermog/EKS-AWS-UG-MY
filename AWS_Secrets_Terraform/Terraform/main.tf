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
  min_special      = 1
  min_upper        = 1
  number           = true
  upper            = true
  override_special = "_%@"
}


resource "aws_secretsmanager_secret" "vault" {
  name = "DBSecrets"
}

resource "aws_secretsmanager_secret_version" "example" {
  secret_id     = aws_secretsmanager_secret.vault.id
  secret_string = random_password.password.result
}

##############################################################################
resource "aws_db_instance" "test_db" {
  name              =  var.db_identifier
  identifier        =  var.db_identifier
  instance_class    = "db.t2.micro"
  allocated_storage = 10
  engine            = "mysql"
  username          = var.db_username
  password          = random_password.password.result
  publicly_accessible = true
  skip_final_snapshot  = true
  vpc_security_group_ids = [aws_security_group.allow_myip.id]
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
