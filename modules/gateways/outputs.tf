output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.igw.id
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = var.enable_nat ? aws_nat_gateway.nat[0].id : null
}

output "nat_gateway_eip" {
  description = "Elastic IP address of the NAT Gateway"
  value       = var.enable_nat ? aws_eip.nat_eip[0].public_ip : null
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "ID of the private route table"
  value       = var.enable_nat ? aws_route_table.private[0].id : null
} 