# Public Subnets
resource "aws_subnet" "public" {
  count = length(var.public_subnets)
  vpc_id = aws_vpc.load_testing_vpc.id
  cidr_block = var.public_subnets[count.index]
  availability_zone = local.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${local.public_subnet_name_prefix}-${count.index + 1}"

    # Allows the AWS Load Balancer Controller to create an internet-facing 
    # load balancer that automatically discovers your subnets.
    # See https://repost.aws/knowledge-center/eks-vpc-subnet-discovery
    "kubernetes.io/role/elb" = "1"

    # Indicates the ownership of the subnets by the EKS cluster.
    # See https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html
    "kubernetes.io/cluster/${local.eks_cluster_name}" = "owned"
  }
}

# Private Subnets
resource "aws_subnet" "private" {
  count = length(var.private_subnets)
  vpc_id = aws_vpc.load_testing_vpc.id
  cidr_block = var.private_subnets[count.index]
  availability_zone = local.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${local.private_subnet_name_prefix}-${count.index + 1}"

    # Allows the AWS Load Balancer Controller to create an internal load balancer 
    # that automatically discovers your subnets.
    # See https://repost.aws/knowledge-center/eks-vpc-subnet-discovery
    "kubernetes.io/role/internal-elb" = "1"

    # Indicates the ownership of the subnets by the EKS cluster.
    # See https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html
    "kubernetes.io/cluster/${local.eks_cluster_name}" = "owned"
  }
}