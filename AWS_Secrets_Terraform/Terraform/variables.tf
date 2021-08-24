variable "region" {
  default     = "ap-southeast-1"
  description = "AWS region"
}
variable db_identifier {
  default     = "testdb"
  description = "db_identifier"
}

variable db_username {
  default     = "mydbuser"
  description = "db_username"
}


variable secret_name {
  default     = "DatabaseParameters"
  description = "The name in AWS Secret Manager"
}

variable "lambda_subnsecurity_group_id" {
  type    = string
  default = "sg-01d04db89fd399088"
}
