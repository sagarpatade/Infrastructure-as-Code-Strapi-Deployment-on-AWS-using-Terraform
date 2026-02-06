# 1. LOAD BALANCER SECURITY GROUP (The Front Gate)
resource "aws_security_group" "alb_sg" {
  name        = "${var.environment}-alb-sg"
  description = "Allow Internet to Load Balancer"
  vpc_id      = var.vpc_id

  # Allow HTTP from ANYWHERE (Internet)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-alb-sg"
  }
}

# 2. APPLICATION SECURITY GROUP (The Secure Door)
resource "aws_security_group" "app_sg" {
  name        = "${var.environment}-app-sg"
  description = "Allow traffic from ALB only"
  vpc_id      = var.vpc_id

  # Allow Traffic ONLY from the Load Balancer on Port 1337 (Strapi)
  ingress {
    from_port       = 1337
    to_port         = 1337
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id] # Source is the ALB SG!
  }

  # Allow SSH (For debugging)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
    # Note: Since the instance is in a Private Subnet, 
    # the internet still can't reach it directly even with this rule.
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-app-sg"
  }
}

# 3. DYNAMIC KEY PAIR (Same as Task 3)
resource "tls_private_key" "my_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "deployer" {
  key_name   = "${var.environment}-key"
  public_key = tls_private_key.my_key.public_key_openssh
}

resource "local_file" "private_key" {
  content         = tls_private_key.my_key.private_key_pem
  filename        = "${path.module}/../../${var.environment}-key.pem"
  file_permission = "0400"
}