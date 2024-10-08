locals {
  # Region us-east-2 (Ohio) has 3 availability zones
  region = "us-east-2"
  availability_zones = ["us-east-2a", "us-east-2b", "us-east-2c"]
  vpc_name = "load-testing-vpc"

  igw_name = "load-testing-igw"
  default_route = "0.0.0.0/0"
  nat_gateway_name_prefix = "load-testing-nat-gateway"
  nat_gateway_eip_name_prefix = "load-testing-nat-gateway-eip"

  public_subnet_name_prefix = "public-load-testing-subnet"
  public_subnet_route_table_name = "public-load-testing-subnet-route-table"

  private_subnet_name_prefix = "private-load-testing-subnet"
  private_subnet_route_table_name = "private-load-testing-subnet-route-table"
  
  eks_cluster_name = "load-testing-eks-cluster"
  eks_kubernetes_version = "1.30"
  eks_cluster_service_role_name = "load-testing-eks-cluster-service-role"
  locust_namespace = "locust"
  fargate_pod_execution_role_name = "load-testing-eks-cluster-fargate-pod-execution-role"
  fargate_profile_name = "load-testing-eks-cluster-fargate-profile"
}

variable "vpc_cidr" {
  description = "CIDR block for the load testing VPC"
  type = string
  default = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "CIDR blocks for the public load testing subnets"
  type = list(string)
  default = ["10.0.0.0/22", "10.0.4.0/22", "10.0.8.0/22"]
}

variable "private_subnets" {
  description = "CIDR blocks for the private load testing subnets"
  type = list(string)
  default = ["10.0.12.0/22", "10.0.16.0/22", "10.0.20.0/22"]
}