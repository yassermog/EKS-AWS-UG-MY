# Input variable definitions

variable "aws_region" {
  description = "AWS region for all resources."

  type    = string
  default = "ap-southeast-1"
}

variable "vpc_id" {
  type    = string
  default = "vpc-110ae874"
}

variable "subnsecurity_group_id" {
  type    = string
  default = "sg-01d04db89fd399088"
}

variable "subnet_id" {
  type    = string
  default = "subnet-8c4bb7e9"
}