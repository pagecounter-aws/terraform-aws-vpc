# Create VPC resource
resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr_block
  tags       = var.vpc_tags
}

# Create subnets for VPC
resource "aws_subnet" "subnet" {
  count                   = length(var.vpc_subnet_cidr_blocks)
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = true
  cidr_block              = var.vpc_subnet_cidr_blocks[count.index]

  tags = {
    Name = aws_vpc.vpc.tags.Name
  }
}

# Create Internet GW for the Public Subnet within VPC
resource "aws_internet_gateway" "vpc_internet_gw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "Internet Gateway for VPC ${aws_vpc.vpc.tags.Name}"
  }
}

# Allocate Elastic IP for NAT GW for Private Subnets within VPC
resource "aws_eip" "nat_gw_ip" {
  vpc = true
}

# Create NAT GW for Private Subnets within VPC
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_gw_ip.id
  # The Subnet ID of the subnet in which to place the gateway. In this case it will be always the first subnet
  subnet_id     = aws_subnet.subnet[0].id
  depends_on    = ["aws_internet_gateway.vpc_internet_gw"]
}

# Create second route table and route for Internet GW for the Public Subnet within VPC
resource "aws_route_table" "second" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc_internet_gw.id
  }

  tags = {
    Name = "custom"
  }
}

# Assosiate second route table with the Public Subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.subnet[0].id
  route_table_id = aws_route_table.second.id
}

# Create route to NAT GW for Private Subnets
resource "aws_route" "internet_access_through_nat_gw" {
  route_table_id         = aws_vpc.vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw.id
}

# Assosiate main route tables with Private subnets
resource "aws_route_table_association" "private" {
  count          = (length(var.vpc_subnet_cidr_blocks) - 1)
  subnet_id      = aws_subnet.subnet[(count.index + 1)].id
  route_table_id = aws_vpc.vpc.main_route_table_id
}
