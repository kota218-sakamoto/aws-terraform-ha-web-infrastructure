# ==============================
# VPC
# ==============================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# ==============================
# Public Subnets
# ==============================

resource "aws_subnet" "public_1a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_1a_cidr
  availability_zone       = var.availability_zone_1a
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-1a"
  }
}

resource "aws_subnet" "public_1c" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_1c_cidr
  availability_zone       = var.availability_zone_1c
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-1c"
  }
}

# ==============================
# Private App Subnets
# ==============================

resource "aws_subnet" "app_1a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.app_subnet_1a_cidr
  availability_zone       = var.availability_zone_1a
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-app-1a"
  }
}

resource "aws_subnet" "app_1c" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.app_subnet_1c_cidr
  availability_zone       = var.availability_zone_1c
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-app-1c"
  }
}

# ==============================
# Private DB Subnets
# ==============================

resource "aws_subnet" "db_1a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.db_subnet_1a_cidr
  availability_zone       = var.availability_zone_1a
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-db-1a"
  }
}

resource "aws_subnet" "db_1c" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.db_subnet_1c_cidr
  availability_zone       = var.availability_zone_1c
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-db-1c"
  }
}

# ==============================
# Internet Gateway
# ==============================

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# ==============================
# Elastic IPs for NAT Gateway
# ==============================

resource "aws_eip" "nat_1a" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip-1a"
  }
}

resource "aws_eip" "nat_1c" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip-1c"
  }
}

# ==============================
# NAT Gateways
# ==============================

resource "aws_nat_gateway" "nat_1a" {
  allocation_id = aws_eip.nat_1a.id
  subnet_id     = aws_subnet.public_1a.id

  depends_on = [aws_internet_gateway.main]

  tags = {
    Name = "${var.project_name}-nat-1a"
  }
}

resource "aws_nat_gateway" "nat_1c" {
  allocation_id = aws_eip.nat_1c.id
  subnet_id     = aws_subnet.public_1c.id

  depends_on = [aws_internet_gateway.main]

  tags = {
    Name = "${var.project_name}-nat-1c"
  }
}

# ==============================
# Public Route Table
# ==============================

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "public_1a" {
  subnet_id      = aws_subnet.public_1a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_1c" {
  subnet_id      = aws_subnet.public_1c.id
  route_table_id = aws_route_table.public.id
}

# ==============================
# Private App Route Tables
# ==============================

resource "aws_route_table" "app_1a" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_1a.id
  }

  tags = {
    Name = "${var.project_name}-app-rt-1a"
  }
}

resource "aws_route_table" "app_1c" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_1c.id
  }

  tags = {
    Name = "${var.project_name}-app-rt-1c"
  }
}

resource "aws_route_table_association" "app_1a" {
  subnet_id      = aws_subnet.app_1a.id
  route_table_id = aws_route_table.app_1a.id
}

resource "aws_route_table_association" "app_1c" {
  subnet_id      = aws_subnet.app_1c.id
  route_table_id = aws_route_table.app_1c.id
}

# ==============================
# Private DB Route Table
# ==============================

resource "aws_route_table" "db" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-db-rt"
  }
}

resource "aws_route_table_association" "db_1a" {
  subnet_id      = aws_subnet.db_1a.id
  route_table_id = aws_route_table.db.id
}

resource "aws_route_table_association" "db_1c" {
  subnet_id      = aws_subnet.db_1c.id
  route_table_id = aws_route_table.db.id
}
