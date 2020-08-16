#-- networking/main.tf ---

data "aws_region" "current" { }

data "aws_availability_zones" "available" {}

locals {
  region  = data.aws_region.current.name
}

resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = { 
    Name = format("%s_vpc", var.project_name)
    project_name = var.project_name
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = { 
    Name = format("%s_igw", var.project_name)
    project_name = var.project_name
  }
}

resource "aws_subnet" "subpub" {
  count                   = length(var.subpub_cidrs)

  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.subpub_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  
  tags = { 
    Name = format("%s_subpub_%d", var.project_name, count.index + 1)
    project_name = var.project_name
  }
}

resource "aws_subnet" "subprv" {
  count                   = length(var.subprv_cidrs)

  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.subprv_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = { 
    Name = format("%s_subprv_%d", var.project_name, count.index + 1)
    project_name = var.project_name
  }
}

resource "aws_security_group" "sg_pub" {
  name        = "sg_pubpub"
  description = "Used for access to the public instances"
  vpc_id      = aws_vpc.vpc.id
  dynamic "ingress" {
    for_each = [ for s in var.service_ports: {
      from_port = s.from_port
      to_port   = s.to_port
    }]
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = "tcp"
      cidr_blocks = [ingress.value.to_port == 27017 ? "0.1.2.3/32" : var.access_ip]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { 
    Name = format("%s_sgpub", var.project_name)
    project_name = var.project_name
  }
}

# Public route table, allows all outgoing traffic to go the the internet gateway.
# https://www.terraform.io/docs/providers/aws/r/route_table.html?source=post_page-----1a7fb9a336e9----------------------
resource "aws_route_table" "rt_pub" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = format("%s_rt_pub", var.project_name)
    project_name = var.project_name
  }
}

# connect every public subnet with our public route table
resource "aws_route_table_association" "rt_pubassoc" {
  count = length(var.subpub_cidrs)

  subnet_id      = aws_subnet.subpub.*.id[count.index]
  route_table_id = aws_route_table.rt_pub.id
}

resource "aws_route_table" "rt_prv" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = format("%s_rt_prv", var.project_name)
    project_name = var.project_name
  }
}

# connect every private subnet with our private route table
resource "aws_route_table_association" "rt_prvassoc" {
  count = length(var.subprv_cidrs)

  subnet_id      = aws_subnet.subprv.*.id[count.index]
  route_table_id = aws_route_table.rt_prv.id
}

resource "aws_eip" "natgw_eip" {
  vpc                       = true
  associate_with_private_ip = "10.0.0.5"

  tags = {
    Name = format("%s_natgw_eip", var.project_name)
    project_name = var.project_name
  }
}

resource "aws_nat_gateway" "natgw" {
  allocation_id = aws_eip.natgw_eip.id
  subnet_id     = aws_subnet.subpub[0].id

  tags = {
    Name = format("%s_natgw", var.project_name)
    project_name = var.project_name
  }

  depends_on = [aws_eip.natgw_eip]
}

resource "aws_route" "natgw_route" {
  route_table_id         = aws_route_table.rt_prv.id
  nat_gateway_id         = aws_nat_gateway.natgw.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_vpc_endpoint" "vpce-log" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${local.region}.logs"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [ aws_security_group.sg_pub.id ]
  subnet_ids          = aws_subnet.subprv.*.id
  private_dns_enabled = true
  tags = {
    Name = format("%s_vpce_log", var.project_name)
    project_name = var.project_name
  }
}