# Create VPC resource
resource "aws_vpc" "new_vpc" {
  cidr_block = var.vpc_cidr_block
  tags       = var.vpc_tags
}

# Create subnets for VPC
resource "aws_subnet" "vpc_subnet" {
  count                   = length(var.vpc_subnet_cidr_blocks)
  vpc_id                  = aws_vpc.new_vpc.id
  map_public_ip_on_launch = true
  cidr_block              = var.vpc_subnet_cidr_blocks[count.index]

  tags = {
    Name = aws_vpc.new_vpc.tags.Name
  }
}

# Create Internet GW for the Public Subnet within VPC
resource "aws_internet_gateway" "vpc_internet_gw" {
  vpc_id = aws_vpc.new_vpc.id

  tags = {
    Name = "Internet Gateway for VPC ${aws_vpc.new_vpc.tags.Name}"
  }
}

# Allocate Elastic IP for NAT GW for Private Subnets within VPC
resource "aws_eip" "nat_gw_ip" {
  vpc = true
}

# Create NAT GW for Private Subnets within VPC
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_gw_ip.id
  subnet_id     = aws_subnet.vpc_subnet[0].id # The Subnet ID of the subnet in which to place the gateway. In this case it will be always the first subnet
  depends_on    = ["aws_internet_gateway.vpc_internet_gw"]
}

# Create second route table and route for Internet GW for the Public Subnet within VPC
resource "aws_route_table" "second" {
  vpc_id = aws_vpc.new_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.vpc_internet_gw.id}"
  }

  tags = {
    Name = "custom"
  }
}

# Assosiate second route table with the Public Subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.vpc_subnet[0].id
  route_table_id = "${aws_route_table.second.id}"
}

# Create route to NAT GW for Private Subnets
resource "aws_route" "internet_access_throug_nat_gw" {
  route_table_id         = aws_vpc.new_vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw.id
}

# Assosiate main route tables with Private subnets
resource "aws_route_table_association" "private" {
  #count          = (length(aws_subnet.vpc_subnet) - 1)
  count          = (length(var.vpc_subnet_cidr_blocks) - 1)
  subnet_id      = aws_subnet.vpc_subnet[(count.index + 1)].id
  route_table_id = aws_vpc.new_vpc.main_route_table_id
}

# Create security group for VPC that allows ssh and icmp echo request/reply inbound traffic 
resource "aws_security_group" "vpc_ssh_icmp_echo_sg" {
  name        = "ssh_icmp_echo_enabled_sg"
  description = "Allow traffic needed for ssh and icmp echo request/reply"
  vpc_id      = aws_vpc.new_vpc.id

  // Custom ICMP Rule - IPv4 Echo Reply
  ingress {
    from_port   = "0"
    to_port     = "-1"
    protocol    = "icmp"
    cidr_blocks = [var.icmp_cidr]
  }

  // Custom ICMP Rule - IPv4 Echo Request
  ingress {
    from_port   = "8"
    to_port     = "-1"
    protocol    = "icmp"
    cidr_blocks = [var.icmp_cidr]
  }

  // ssh
  ingress {
    from_port   = var.ssh_port
    to_port     = var.ssh_port
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr]
  }

  // all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = aws_vpc.new_vpc.tags.Name
  }
}
