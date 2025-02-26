output "peering_connection_id" {
  description = "The ID of the VPC Peering Connection"
  value       = aws_vpc_peering_connection.peering.id
}

output "peering_connection_status" {
  description = "The status of the VPC Peering Connection"
  value       = aws_vpc_peering_connection.peering.accept_status
}

output "requester_cidr" {
  description = "CIDR block of requester VPC"
  value       = data.aws_vpc.requester.cidr_block
}

output "accepter_cidr" {
  description = "CIDR block of accepter VPC"
  value       = data.aws_vpc.accepter.cidr_block
} 