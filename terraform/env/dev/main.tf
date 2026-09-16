resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name        = "retail-platform-vpc"
    environment = "dev"
    project     = "retail-platform"
  }
}

resource "aws_subnet" "public" {
  for_each                = var.public_subnet_cidrs
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr_block
  availability_zone       = data.aws_availability_zones.available.names[each.value.availability_zone]
  map_public_ip_on_launch = true
  tags = {
    Name        = "retail-platform-public-subnet-${each.key}"
    environment = "dev"
    project     = "retail-platform"
  }
}

resource "aws_subnet" "private" {
  for_each                = var.private_subnet_cidrs
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr_block
  availability_zone       = data.aws_availability_zones.available.names[each.value.availability_zone]
  map_public_ip_on_launch = false
  tags = {
    Name        = "retail-platform-private-subnet-${each.key}"
    environment = "dev"
    project     = "retail-platform"
  }
}

#-----------------------------------------------Internet Gateway and NAT Gateway-----------------------------------------------

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name        = "retail-platform-igw"
    environment = "dev"
    project     = "retail-platform"
  }
}

resource "aws_eip" "private_nat" {
  for_each = var.private_subnet_cidrs
  domain   = "vpc"
}

resource "aws_nat_gateway" "private" {
  for_each      = var.private_subnet_cidrs
  subnet_id     = aws_subnet.public[each.key].id
  allocation_id = aws_eip.private_nat[each.key].id
  tags = {
    Name        = "retail-platform-private-nat-${each.key}"
    environment = "dev"
    project     = "retail-platform"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name        = "retail-platform-public-rt"
    environment = "dev"
    project     = "retail-platform"
  }
}

resource "aws_route_table" "private" {
  for_each = var.private_subnet_cidrs
  vpc_id   = aws_vpc.main.id
  tags = {
    Name        = "retail-platform-private-rt-${each.key}"
    environment = "dev"
    project     = "retail-platform"
  }
}


resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route" "private_nat" {
  for_each               = var.private_subnet_cidrs
  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.private[each.key].id
}

resource "aws_route_table_association" "public" {
  for_each       = var.public_subnet_cidrs
  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  for_each       = var.private_subnet_cidrs
  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}
