# Outputs VPC id
output "vpc_id" {
  value = aws_vpc.new_vpc.id
}

# Outputs value of VPC tag Name
output "vpc_name" {
  value = aws_vpc.new_vpc.tags.Name
}

# Outputs subnets per VPC
output "subnet_ids" {
  value = aws_subnet.vpc_subnet.*.id
}

# Outputs availability zones in which subnet is created
output "azs" {
  value = aws_subnet.vpc_subnet.*.availability_zone
}
