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