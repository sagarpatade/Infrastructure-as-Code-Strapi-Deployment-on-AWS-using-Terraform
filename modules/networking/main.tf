# 1. The Virtual Private Cloud (The Building)
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.environment}-vpc"
  }
}

# 2. Public Subnet (For Load Balancer & NAT)
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true # Instances get public IPs here automatically
  availability_zone       = "${var.region}a"

  tags = {
    Name = "${var.environment}-public-subnet"
  }
}

# 3. Private Subnet (For Strapi)
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = "${var.region}a"

  tags = {
    Name = "${var.environment}-private-subnet"
  }
}

# 4. Internet Gateway (To the Internet)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.environment}-igw"
  }
}

# 5. Elastic IP for NAT (Fixed Static IP)
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

# 6. NAT Gateway (Allows Private Subnet to download Docker updates)
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public.id 

  tags = {
    Name = "${var.environment}-nat-gw"
  }
  
  # Wait for IGW to be ready first
  depends_on = [aws_internet_gateway.igw]
}

# 7. Public Route Table (Traffic to Internet Gateway)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.environment}-public-rt"
  }
}

# 8. Private Route Table (Traffic to NAT Gateway)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "${var.environment}-private-rt"
  }
}

# 9. Associations (Connecting Subnets to Route Tables)
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# modules/networking/main.tf

# ... (Keep all existing code) ...

# NEW: Public Subnet 2 (In a different Availability Zone)
resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"       # Different CIDR
  map_public_ip_on_launch = true
  availability_zone       = "${var.region}b"    # <--- ZONE B (Different AZ)

  tags = {
    Name = "${var.environment}-public-subnet-2"
  }
}

# NEW: Associate Subnet 2 with the Public Route Table
resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}