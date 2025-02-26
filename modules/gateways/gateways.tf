variable "master" {}
variable "env" {}
variable "vpc_id" {}
variable "public_subnet_id" {}
variable "enable_nat" {
  type    = bool
  default = true
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = var.vpc_id

  tags = {
    Name        = "${var.master.convention}-${var.env}-igw"
    Environment = var.env
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat_eip" {
  count = var.enable_nat ? 1 : 0
  domain = "vpc"

  tags = {
    Name        = "${var.master.convention}-${var.env}-nat-eip"
    Environment = var.env
  }
}

# NAT Gateway
resource "aws_nat_gateway" "nat" {
  count = var.enable_nat ? 1 : 0
  
  allocation_id = aws_eip.nat_eip[0].id
  subnet_id     = var.public_subnet_id

  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name        = "${var.master.convention}-${var.env}-nat"
    Environment = var.env
  }
}

# Route table for public subnets
resource "aws_route_table" "public" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name        = "${var.master.convention}-${var.env}-public-rt"
    Environment = var.env
  }
}

# Route table for private subnets
resource "aws_route_table" "private" {
  count  = var.enable_nat ? 1 : 0
  vpc_id = var.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[0].id
  }

  tags = {
    Name        = "${var.master.convention}-${var.env}-private-rt"
    Environment = var.env
  }
} 