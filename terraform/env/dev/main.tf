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



