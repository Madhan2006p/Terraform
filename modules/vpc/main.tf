# ──────────────────────────────────────────────────────────────
# VPC Module – Creates a full public networking stack:
#   VPC → Subnet → Internet Gateway → Route Table
# ──────────────────────────────────────────────────────────────

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name      = "terraform-docker-vpc"
    ManagedBy = "terraform"
  }
}

resource "aws_subnet" "subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name      = "terraform-docker-public-subnet"
    ManagedBy = "terraform"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name      = "terraform-docker-igw"
    ManagedBy = "terraform"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name      = "terraform-docker-public-rt"
    ManagedBy = "terraform"
  }
}

resource "aws_route_table_association" "public_subnet" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.public.id
}
