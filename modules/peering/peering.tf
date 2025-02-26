variable "master" {}
variable "env" {}
variable "requester_vpc_id" {}
variable "accepter_vpc_id" {}
variable "requester_region" {
  default = null
}
variable "accepter_region" {
  default = null
}
variable "auto_accept" {
  default = true
}

# Create the peering connection
resource "aws_vpc_peering_connection" "peering" {
  vpc_id      = var.requester_vpc_id
  peer_vpc_id = var.accepter_vpc_id
  peer_region = var.accepter_region
  auto_accept = var.auto_accept && var.accepter_region == null ? true : false

  tags = {
    Name        = "${var.master.convention}-${var.env}-peering"
    Environment = var.env
  }
}

# Accept the peering connection (for cross-region peering)
resource "aws_vpc_peering_connection_accepter" "accepter" {
  count = var.accepter_region != null ? 1 : 0
  
  vpc_peering_connection_id = aws_vpc_peering_connection.peering.id
  auto_accept              = var.auto_accept

  tags = {
    Name        = "${var.master.convention}-${var.env}-peering-accepter"
    Environment = var.env
  }
}

# Get route tables for both VPCs
data "aws_route_tables" "requester" {
  vpc_id = var.requester_vpc_id
}

data "aws_route_tables" "accepter" {
  vpc_id = var.accepter_vpc_id
}

# Get CIDR blocks for both VPCs
data "aws_vpc" "requester" {
  id = var.requester_vpc_id
}

data "aws_vpc" "accepter" {
  id = var.accepter_vpc_id
}

# Create routes in requester VPC
resource "aws_route" "requester_routes" {
  count = length(data.aws_route_tables.requester.ids)
  
  route_table_id            = data.aws_route_tables.requester.ids[count.index]
  destination_cidr_block    = data.aws_vpc.accepter.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peering.id
}

# Create routes in accepter VPC
resource "aws_route" "accepter_routes" {
  count = length(data.aws_route_tables.accepter.ids)
  
  route_table_id            = data.aws_route_tables.accepter.ids[count.index]
  destination_cidr_block    = data.aws_vpc.requester.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peering.id
} 