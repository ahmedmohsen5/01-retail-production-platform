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
    Name                     = "retail-platform-public-subnet-${each.key}"
    environment              = "dev"
    project                  = "retail-platform"
    "kubernetes.io/role/elb" = "1"
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
  tags = {
    Name        = "retail-platform-private-nat-eip-${each.key}"
    environment = "dev"
    project     = "retail-platform"
  }
}

resource "aws_nat_gateway" "private" {
  for_each      = var.private_subnet_cidrs
  subnet_id     = aws_subnet.public[each.key].id
  allocation_id = aws_eip.private_nat[each.key].id
  depends_on    = [aws_internet_gateway.main]
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

#-----------------------------------------------security groups-----------------------------------------------

resource "aws_security_group" "alb-sg" {
  name        = "retail-platform-alb-sg"
  description = "Security group for the Application Load Balancer"
  vpc_id      = aws_vpc.main.id
  tags = {
    Name        = "retail-platform-alb-sg"
    environment = "dev"
    project     = "retail-platform"
  }
}
resource "aws_security_group" "eks-sg" {
  name        = "retail-platform-eks-sg"
  description = "Security group for the EKS cluster"
  vpc_id      = aws_vpc.main.id
  tags = {
    Name        = "retail-platform-eks-sg"
    environment = "dev"
    project     = "retail-platform"
  }
}

resource "aws_security_group" "eks-node-sg" {
  name        = "retail-platform-eks-node-sg"
  description = "Security group for the EKS worker nodes"
  vpc_id      = aws_vpc.main.id
  tags = {
    Name        = "retail-platform-eks-node-sg"
    environment = "dev"
    project     = "retail-platform"
  }

}

resource "aws_vpc_security_group_ingress_rule" "alb-http" {
  security_group_id = aws_security_group.alb-sg.id
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "alb-https" {
  security_group_id = aws_security_group.alb-sg.id
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "eks-https" {
  security_group_id            = aws_security_group.eks-sg.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.eks-node-sg.id
}

resource "aws_vpc_security_group_egress_rule" "eks-10250-egress" {
  security_group_id            = aws_security_group.eks-sg.id
  from_port                    = 10250
  to_port                      = 10250
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.eks-node-sg.id
}

resource "aws_vpc_security_group_ingress_rule" "eks-node-10250" {
  security_group_id            = aws_security_group.eks-node-sg.id
  from_port                    = 10250
  to_port                      = 10250
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.eks-sg.id
}

resource "aws_vpc_security_group_ingress_rule" "eks-node-to-node-traffic" {
  security_group_id            = aws_security_group.eks-node-sg.id
  ip_protocol                  = "-1"
  referenced_security_group_id = aws_security_group.eks-node-sg.id
}

resource "aws_vpc_security_group_egress_rule" "eks-node-https" {
  security_group_id = aws_security_group.eks-node-sg.id
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}
