# --- networking/main.tf ---

data "aws_availability_zones" "available" {
}

resource "random_integer" "random" {
  min = 1
  max = 100
}

resource "random_shuffle" "az_list" {
  input        = data.aws_availability_zones.available.names
  result_count = var.max_subnets
}

# Create VPC
resource "aws_vpc" "tt_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "tt_vpc-${random_integer.random.id}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

### PUBLIC SUBNETS

# Create public subnets for frontend
# Includes: NAT gateway for private subnets
resource "aws_subnet" "tt_public_subnet_front" {
  count                   = var.sn_count
  vpc_id                  = aws_vpc.tt_vpc.id
  cidr_block              = var.public_cidrs_front[count.index]
  map_public_ip_on_launch = true
  availability_zone       = random_shuffle.az_list.result[count.index]
  tags = {
    Name = "tt_public_front_${count.index + 1}"
  }
}

# Create public subnets for backend
# Includes: NAT gateway for private subnets
resource "aws_subnet" "tt_public_subnet_back" {
  count                   = var.sn_count
  vpc_id                  = aws_vpc.tt_vpc.id
  cidr_block              = var.public_cidrs_back[count.index]
  map_public_ip_on_launch = true
  availability_zone       = random_shuffle.az_list.result[count.index]
  tags = {
    Name = "tt_public_back_${count.index + 1}"
  }
}

# Create Internet Gateway for the VPC
resource "aws_internet_gateway" "tt_internet_gateway" {
  vpc_id = aws_vpc.tt_vpc.id

  tags = {
    Name = "tt_igw"
  }
}

# Create route table for the VPC
# This will be the default route table for the subnets if they don't have a route table of their own
resource "aws_route_table" "tt_public_rt" {
  vpc_id = aws_vpc.tt_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tt_internet_gateway.id
  }

  tags = {
    Name = "tt_public"
  }
}

# Create default route table for the VPC
resource "aws_default_route_table" "tt_private_rt" {
  default_route_table_id = aws_vpc.tt_vpc.default_route_table_id

  tags = {
    Name = "tt_default_for_vpc"
  }
}

# Create default route entry
resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.tt_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.tt_internet_gateway.id
}

# Asociate default route table to the public front subnet
resource "aws_route_table_association" "tt_public_front_assoc" {
  count          = var.sn_count
  subnet_id      = aws_subnet.tt_public_subnet_front.*.id[count.index]
  route_table_id = aws_route_table.tt_public_rt.id
}

# Asociate default route table to the public back subnet
resource "aws_route_table_association" "tt_public_back_assoc" {
  count          = var.sn_count
  subnet_id      = aws_subnet.tt_public_subnet_back.*.id[count.index]
  route_table_id = aws_route_table.tt_public_rt.id
}

# Create one NAT for each AZ to allow private subnets to reach the Internet.
resource "aws_eip" "tt_allocation_id" {
  count = var.sn_count
  vpc   = true
}

resource "aws_nat_gateway" "tt_nat_gateway" {
  allocation_id = aws_eip.tt_allocation_id.*.id[count.index]
  count         = var.sn_count
  subnet_id     = aws_subnet.tt_public_subnet_front.*.id[count.index]

  tags = {
    Name = "tt_nat_${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.tt_internet_gateway]
}


### PRIVATE SUBNETS

# Create private subnets for frontend
# Includes: EC2 instances for frontend
resource "aws_subnet" "tt_private_subnet_front" {
  count                   = var.sn_count
  vpc_id                  = aws_vpc.tt_vpc.id
  cidr_block              = var.private_cidrs_front[count.index]
  map_public_ip_on_launch = false
  availability_zone       = random_shuffle.az_list.result[count.index]
  tags = {
    Name = "tt_private_front_${count.index + 1}"
  }
}

# Create route table for the private frontend subnet
# Default route for this table points to the proper frontend NAT gateway
resource "aws_route_table" "tt_private_rt_front" {
  vpc_id = aws_vpc.tt_vpc.id
  count  = var.sn_count

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.tt_nat_gateway.*.id[count.index]
  }

  tags = {
    Name = "tt_private_rt_front_${count.index + 1}"
  }
}

# Asociate route table to the private frontend subnet
resource "aws_route_table_association" "tt_private_front_assoc" {
  count          = var.sn_count
  subnet_id      = aws_subnet.tt_private_subnet_front.*.id[count.index]
  route_table_id = aws_route_table.tt_private_rt_front.*.id[count.index]
}

# Create private subnets for backend
# Includes: EC2 instances for backend
resource "aws_subnet" "tt_private_subnet_back" {
  count                   = var.sn_count
  vpc_id                  = aws_vpc.tt_vpc.id
  cidr_block              = var.private_cidrs_back[count.index]
  map_public_ip_on_launch = false
  availability_zone       = random_shuffle.az_list.result[count.index]
  tags = {
    Name = "tt_private_back_${count.index + 1}"
  }
}

# Create route table for the private backend subnet
# Default route for this table points to the proper backend NAT gateway
resource "aws_route_table" "tt_private_rt_back" {
  vpc_id = aws_vpc.tt_vpc.id
  count  = var.sn_count

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.tt_nat_gateway.*.id[count.index]
  }

  tags = {
    Name = "tt_private_rt_back_${count.index + 1}"
  }
}

# Asociate route table to the private backend subnet
resource "aws_route_table_association" "tt_private_back_assoc" {
  count          = var.sn_count
  subnet_id      = aws_subnet.tt_private_subnet_back.*.id[count.index]
  route_table_id = aws_route_table.tt_private_rt_back.*.id[count.index]
}


# Create security groups
resource "aws_security_group" "tt_sg" {
  for_each = var.security_groups

  name        = each.value.name
  description = each.value.description
  vpc_id      = aws_vpc.tt_vpc.id

  dynamic "ingress" {
    for_each = each.value.ingress
    content {
      from_port   = ingress.value.from
      to_port     = ingress.value.to
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# RDS
# Create private subnets for RDS
resource "aws_subnet" "tt_private_subnet_rds" {
  count                   = var.sn_count
  vpc_id                  = aws_vpc.tt_vpc.id
  cidr_block              = var.private_cidrs_rds[count.index]
  map_public_ip_on_launch = false
  availability_zone       = random_shuffle.az_list.result[count.index]
  tags = {
    Name = "tt_private_rds_${count.index + 1}"
  }
}

resource "aws_db_subnet_group" "tt_rds_subnetgroup" {
  count = var.sn_count
  #  count = var.db_subnet_group == true ? 1: 0
  name       = "tt_rds_subnetgroup_${count.index + 1}"
  subnet_ids = aws_subnet.tt_private_subnet_rds.*.id
  tags = {
    Name = "tt_rds_sng"
  }
}
