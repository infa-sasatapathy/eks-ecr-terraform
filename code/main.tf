provider "aws" {
#  region = "us-east-1"
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version = "~> 20.0" # or the latest stable version
  cluster_name    = "my-eks-cluster"
  cluster_version = "1.31" # Replace with desired Kubernetes version
  subnet_ids = module.vpc.private_subnets
  vpc_id          = module.vpc.vpc_id
  eks_managed_node_groups = {
  eks_nodes = {
    desired_size = 2
    max_size     = 3
    min_size     = 1

    instance_types = ["t3.medium"]
  }
}
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name            = "eks-vpc"
  cidr            = "10.0.0.0/16"
  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  enable_nat_gateway = true
  map_public_ip_on_launch       = true
}

locals {
  ecr_url = "${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.ecr_repo_name}"
}
