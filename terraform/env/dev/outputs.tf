output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = [for subnet in aws_subnet.public : subnet.id]
}

output "private_subnet_ids" {
  value = [for subnet in aws_subnet.private : subnet.id]
}

output "selected_az_names" {
  value = slice(data.aws_availability_zones.available.names, 0, length(var.public_subnet_cidrs))
}

output "vpc_cidr" {
  value = aws_vpc.main.cidr_block
}

#-----------------------------------------------Internet Gateway and NAT Gateway-----------------------------------------------
output "internet_gateway_id" {
  value = aws_internet_gateway.main.id
}

output "nat_gateway_ids" {
  value = [for nat in aws_nat_gateway.private : nat.id]
}

output "nat_gateway_ips" {
  value = [for nat in aws_nat_gateway.private : nat.public_ip]
}

output "public_route_table_ids" {
  value = aws_route_table.public.id
}

output "private_route_table_ids" {
  value = [for rt in aws_route_table.private : rt.id]
}