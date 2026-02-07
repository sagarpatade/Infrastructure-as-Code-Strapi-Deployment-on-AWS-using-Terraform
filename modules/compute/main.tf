# 1. THE EC2 INSTANCE (Hidden in Private Subnet)
resource "aws_instance" "strapi_server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.private_subnet_id
  
  # CHANGE 1: Security Group attached
vpc_security_group_ids = [var.app_sg_id]

# CHANGE 2: Attach the SSM Role (Enables Secure Console Connection without Public IP)
iam_instance_profile = var.iam_instance_profile

root_block_device {
    volume_size = 20    # 20 GB Storage to prevent disk full errors
    volume_type = "gp3"
  }

  # 3. USER DATA (The "Compatibility Configuration": Node 20 + Strapi v4)
  # 2. USER DATA (Final Fix: Removed broken '--host' flag)
  user_data = <<-EOF
              #!/bin/bash
              
              # A. Install Docker
              sudo apt-get update
              sudo apt-get install -y docker.io
              sudo systemctl start docker
              sudo systemctl enable docker
              
              # B. Create Dockerfile
              # We use Node 20 Bullseye (Required for dependencies)
              cat <<EOT >> /home/ubuntu/Dockerfile
              FROM node:20-bullseye
              
              # 1. Install System Dependencies
              RUN apt-get update && apt-get install -y \
                  libvips-dev \
                  python3 \
                  make \
                  g++ \
                  git
              
              WORKDIR /srv/app
              
              # 2. Create Strapi v4 App
              # We use v4.25.4 (Stable)
              RUN npx create-strapi-app@4.25.4 my-project \
                  --quickstart \
                  --no-run \
                  --skip-cloud
              
              WORKDIR /srv/app/my-project
              
              # 3. Force Rebuild
              RUN npm rebuild sharp
              
              # 4. Build Admin Panel
              RUN npm run build
              
              # 5. Set Environment Variables (The Correct Way)
              # Strapi will read these automatically. No flags needed!
              ENV HOST=0.0.0.0
              ENV PORT=1337
              ENV APP_KEYS="toBeModified1,toBeModified2"
              ENV API_TOKEN_SALT="tobemodified"
              ENV ADMIN_JWT_SECRET="tobemodified"
              ENV TRANSFER_TOKEN_SALT="tobemodified"
              ENV JWT_SECRET="tobemodified"
              ENV NODE_ENV=development
              
              # 6. Start Server (FIX: Removed the crashing '--host' flag)
              EXPOSE 1337
              CMD ["npm", "run", "develop"]
              EOT
              
              # C. Build & Run
              cd /home/ubuntu
              sudo docker build -t strapi-stable .
              sudo docker run -d -p 1337:1337 --restart always --name strapi strapi-stable
              EOF

  tags = {
    Name = "${var.environment}-strapi-server"
  }
}

# 2. CONNECT TO LOAD BALANCER
resource "aws_lb_target_group_attachment" "strapi_attach" {
  target_group_arn = var.target_group_arn
  target_id        = aws_instance.strapi_server.id
  port             = 1337
}

# ---------------------------------------------------------
# BASTION HOST RESOURCES
# ---------------------------------------------------------

# 1. Bastion Security Group
resource "aws_security_group" "bastion_sg" {
  name        = "bastion-security-group"
  description = "Allow SSH access"
  vpc_id      = var.vpc_id

  # Inbound: Allow SSH from ANYWHERE (For troubleshooting only)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound: Allow all traffic out
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Task4-Bastion-SG"
  }
}

# 2. The Bastion EC2 Instance
resource "aws_instance" "bastion" {
  ami                         = var.ami_id
  instance_type               = "t2.micro"
  key_name                    = var.key_name
  
  # IMPORTANT: This must be the PUBLIC subnet ID so you can reach it
  subnet_id                   = var.public_subnet_id 
  
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "Task4-Bastion-Host"
  }
}