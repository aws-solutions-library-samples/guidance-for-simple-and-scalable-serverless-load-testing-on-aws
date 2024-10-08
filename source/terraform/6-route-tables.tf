# Public Route Table to Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.load_testing_vpc.id

  route {
    cidr_block = local.default_route
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = local.public_subnet_route_table_name
  }

  depends_on = [
    aws_internet_gateway.igw
  ]
}

# Associate public subnets with public route table
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)
  subnet_id = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private Route Tables to NAT Gateways
resource "aws_route_table" "private" {
  count  = length(aws_subnet.private)
  vpc_id = aws_vpc.load_testing_vpc.id

  route {
    cidr_block = local.default_route
    gateway_id = aws_nat_gateway.nat[count.index].id
  }

  tags = {
    Name = "${local.private_subnet_route_table_name}-${count.index + 1}"
  }

  depends_on = [ 
    aws_nat_gateway.nat
  ]
}

# Associate private subnets with private route tables
resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)
  subnet_id = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id

  depends_on = [
    aws_route_table.private
  ]
}