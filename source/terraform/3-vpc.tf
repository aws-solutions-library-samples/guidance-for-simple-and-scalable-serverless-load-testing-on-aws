resource "aws_vpc" "load_testing_vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = local.vpc_name
  }
}

# Default security group restricting all traffic by omitting ingress and egress rules
resource "aws_default_security_group" "default_security_group" {
  vpc_id = aws_vpc.load_testing_vpc.id
}