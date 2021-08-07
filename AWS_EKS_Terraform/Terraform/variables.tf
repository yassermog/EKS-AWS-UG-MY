variable "region" {
  default     = "ap-southeast-1"
  description = "AWS region"
}
variable "vpc_name" {
  default = "eks-vpc"
}
variable "node_group_name" {
  default = "aws-usg-my-node-group"
}
variable "cluster_name" {
  default = "aws-usg-my-eks"
}
variable "max_size" {
  default = 1
}
variable "min_size" {
  default = 1
}
variable "instance_type" {
  default = "t2.medium"
}

variable "asg_desired_capacity" {
  default = "1"
}
variable "eks_cluster_role" {
  default = "eks_cluster_role"
}

variable "cidr_a" {
  default = "10.0.1.0/24"
}
variable "cidr_b" {
  default = "10.0.2.0/24"
}
variable "cidr_c" {
  default = "10.0.3.0/24"
}
variable "desired_size" {
  default = 1
}


variable "eks_node_role_name" {
  default = "eks_node_role"
}
