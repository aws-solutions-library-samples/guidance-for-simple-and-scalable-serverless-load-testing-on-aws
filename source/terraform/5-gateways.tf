# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.load_testing_vpc.id

  tags = {
    Name = local.igw_name
  }
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  count = length(aws_subnet.public)
  domain = "vpc"

  tags = {
    Name = "${local.nat_gateway_eip_name_prefix}-${count.index + 1}"
  }
}

# NAT Gateways
resource "aws_nat_gateway" "nat" {
  count = length(aws_subnet.public)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id = aws_subnet.public[count.index].id

  tags = {
    Name = "${local.nat_gateway_name_prefix}-${count.index + 1}"
  }

  depends_on = [aws_eip.nat]
}