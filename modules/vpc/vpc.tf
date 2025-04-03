#VPC
resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr_block
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  tags = {
    Name = "${var.project.env}-${var.project.name}"
  }
}

#Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.vpc.id
  for_each                = var.subnet_az
  availability_zone       = each.key
  map_public_ip_on_launch = true
  cidr_block              = cidrsubnet(var.cidr_block, 4, each.value) #4 subnet across 2 az
  tags = {
    Name   = "${var.project.env}-${var.project.name}-public-subnet"
    Role   = "public"
    Subnet = "${each.key}-${each.value}"
  }
}

#Private Subnet
resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.vpc.id
  for_each                = var.subnet_az
  availability_zone       = each.key
  map_public_ip_on_launch = true
  cidr_block              = cidrsubnet(var.cidr_block, 4, each.value + length(var.subnet_az))
  tags = {
    Name   = "${var.project.env}-${var.project.name}-private-subnet"
    Role   = "private"
    Subnet = "${each.key}-${each.value}"
  }
}

#Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.project.env}-${var.project.name}-igw"
  }
}

#Elastic IP
resource "aws_eip" "eip" {
  domain = "vpc"

  lifecycle {
    # prevent_destroy = true 
  }

  tags = {
    Name = "${var.project.env}-${var.project.name}-eip"
    Description = "Elastic IP for NAT Gateway"
    VPC  = aws_vpc.vpc.id
  }
}

#NAT Gateway
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public[element(keys(aws_subnet.public), 0)].id
  tags = {
    Name = "${var.project.env}-${var.project.name}-natgw"
  }
}

#Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.project.env}-${var.project.name}-public-rt"
  }
}

#Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.project.env}-${var.project.name}-private-rt"
  }
}

#Public route table to Internet Gateway
resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

#Private route table to NAT Gateway
resource "aws_route" "private" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.nat.id
  lifecycle {
    ignore_changes = [gateway_id, nat_gateway_id]
  }
}

#Associate Public Subnet to Public Route Table
resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public.id
}

#Associate Private Subnet to Private Route Table
resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private.id
}

