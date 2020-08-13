#-- networking/main.tf ---

data "aws_region" "current" { }

data "aws_availability_zones" "available" {}

locals {
  region  = data.aws_region.current.name
}

resource "aws_vpc" "tfec2lambdacw_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = { 
    Name = format("%s_vpc", var.project_name)
    project_name = var.project_name
  }
}

resource "aws_internet_gateway" "tfec2lambdacw_igw" {
  vpc_id = aws_vpc.tfec2lambdacw_vpc.id

  tags = { 
    Name = format("%s_igw", var.project_name)
    project_name = var.project_name
  }
}

resource "aws_subnet" "tfec2lambdacw_subpub" {
  count                   = length(var.subpub_cidrs)

  vpc_id                  = aws_vpc.tfec2lambdacw_vpc.id
  cidr_block              = var.subpub_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  
  tags = { 
    Name = format("%s_subpub_%d", var.project_name, count.index + 1)
    project_name = var.project_name
  }
}

resource "aws_subnet" "tfec2lambdacw_subprv" {
  count                   = length(var.subprv_cidrs)

  vpc_id                  = aws_vpc.tfec2lambdacw_vpc.id
  cidr_block              = var.subprv_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = { 
    Name = format("%s_subprv_%d", var.project_name, count.index + 1)
    project_name = var.project_name
  }
}

resource "aws_security_group" "tfec2lambdacw_sg" {
  name        = "tfec2lambdacw_sgpub"
  description = "Used for access to the public instances"
  vpc_id      = aws_vpc.tfec2lambdacw_vpc.id
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
resource "aws_route_table" "tfec2lambdacw_rtpub" {
  vpc_id = aws_vpc.tfec2lambdacw_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tfec2lambdacw_igw.id
  }
  tags = {
    Name = format("%s_tfec2lambdacw_rtpub", var.project_name)
    project_name = var.project_name
  }
}

# connect every public subnet with our public route table
resource "aws_route_table_association" "tfec2lambdacw_rtpubassoc" {
  count = length(var.subpub_cidrs)

  subnet_id      = aws_subnet.tfec2lambdacw_subpub.*.id[count.index]
  route_table_id = aws_route_table.tfec2lambdacw_rtpub.id
}

# If the subnet is not associated with any route by default it will be 
# associated automatically with this Private Route table.
# That's why we don't need an aws_route_table_association for private route tables.
# When Terraform first adopts the Default Route Table, it immediately removes all defined routes. 
# It then proceeds to create any routes specified in the configuration. 
# This step is required so that only the routes specified in the configuration present in the 
# Default Route Table.
# https://www.terraform.io/docs/providers/aws/r/default_route_table.html
resource "aws_default_route_table" "tfec2lambdacw_rtprv" {
  default_route_table_id = aws_vpc.tfec2lambdacw_vpc.default_route_table_id
  tags = {
    Name = format("%s_tfec2lambdacw_rtprv", var.project_name)
    project_name = var.project_name
  }
}

resource "aws_vpc_endpoint" "vpce-log" {
  vpc_id              = aws_vpc.tfec2lambdacw_vpc.id
  service_name        = "com.amazonaws.${local.region}.logs"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [ aws_security_group.tfec2lambdacw_sg.id ]
  subnet_ids          = aws_subnet.tfec2lambdacw_subprv.*.id
  private_dns_enabled = true
  tags = {
    Name = format("%s_vpce_log", var.project_name)
    project_name = var.project_name
  }
}