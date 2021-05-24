############################### Terrafrom Setup ###############################
terraform {

  backend "s3" {
    bucket = "aws-usg-my-eks-pres"
    key    = ".tfstate"
    region = "ap-southeast-1"
  }
}

provider "aws" {
  region = var.region
}
############################### END Setup ###############################


############################### Networking ###############################
##### VPC #####

resource "aws_vpc" "eks_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = var.vpc_name
  }
}

resource "aws_internet_gateway" "eks_vpc_igw" {
  vpc_id = aws_vpc.eks_vpc.id
  tags = {
    Name = var.vpc_name
  }
}



#=================================================
#Creating  Public Subnets
#=================================================
resource "aws_subnet" "public_subnet_a" {
  map_public_ip_on_launch = true
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = var.cidr_a
  availability_zone       = "${var.region}a"
  tags = {
    Name                                        = "${var.cluster_name}-public-a"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }
}

resource "aws_subnet" "public_subnet_b" {
  map_public_ip_on_launch = true
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = var.cidr_b
  availability_zone       = "${var.region}b"
  tags = {
    Name                                        = "${var.cluster_name}-public-b"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }
}

resource "aws_subnet" "public_subnet_c" {
  map_public_ip_on_launch = true
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = var.cidr_c
  availability_zone       = "${var.region}c"
  tags = {
    Name                                        = "${var.cluster_name}-public-c"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }
}



#=================================================
#Creating Route Table
#=================================================

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.eks_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks_vpc_igw.id
  }

  tags = {
    Name = "public_eks_route_table"
  }

}
#=================================================
#Creating 3 Data Subnet Route Table Association
#=================================================

resource "aws_route_table_association" "rt-a-association" {
  subnet_id      = "${aws_subnet.public_subnet_a.id}"
  route_table_id = "${aws_route_table.public_route_table.id}"
}


resource "aws_route_table_association" "rt-b-association" {
  subnet_id      = "${aws_subnet.public_subnet_b.id}"
  route_table_id = "${aws_route_table.public_route_table.id}"
}

resource "aws_route_table_association" "rt-c-association" {
  subnet_id      = "${aws_subnet.public_subnet_c.id}"
  route_table_id = "${aws_route_table.public_route_table.id}"
}

#####  security_group #####
resource "aws_security_group" "worker_sg" {
  name_prefix = "eks_worker_group"
  vpc_id      = aws_vpc.eks_vpc.id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "10.0.0.0/8",
    ]
  }
}

#=================================================
#                   EKS
#================================================= 
resource "aws_eks_cluster" "eks" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_role.arn

  encryption_config {
    resources = ["secrets"]
    provider {
      key_arn = aws_kms_key.eks-cluster-key.arn
    }
  }
  enabled_cluster_log_types = ["api", "audit", "authenticator", "scheduler", "controllerManager"]

  vpc_config {
    security_group_ids      = [aws_security_group.worker_sg.id]
    endpoint_private_access = false
    endpoint_public_access  = true
    subnet_ids              = [aws_subnet.public_subnet_a.id, aws_subnet.public_subnet_b.id, aws_subnet.public_subnet_c.id]
  }
  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.policy-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.policy-AmazonEKSVPCResourceController,
  ]
}

resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = var.cluster_name
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.eks_node_group_role.arn
  ami_type        = "AL2_x86_64"
  disk_size       = 16
  instance_types  = [var.instance_type]
  subnet_ids      = [aws_subnet.public_subnet_a.id, aws_subnet.public_subnet_b.id, aws_subnet.public_subnet_c.id]
  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_eks_cluster.eks,
    aws_iam_role_policy_attachment.policy-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.policy-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.policy-AmazonEC2ContainerRegistryReadOnly,
  ]
}

############## EKS IAM #############

resource "aws_iam_role" "eks_role" {
  name = var.eks_cluster_role

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "policy-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_role.name
}

# Optionally, enable Security Groups for Pods
# Reference: https://docs.aws.amazon.com/eks/latest/userguide/security-groups-for-pods.html
resource "aws_iam_role_policy_attachment" "policy-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_role.name
}



resource "aws_iam_role" "eks_node_group_role" {
  name = var.eks_node_role_name
  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "policy-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "policy-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "policy-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_kms_key" "eks-cluster-key" {
  description         = "EKS Cluster Encryption Config KMS Key"
  enable_key_rotation = true
}
