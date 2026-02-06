# 1. THE EC2 INSTANCE (Hidden in Private Subnet)
resource "aws_instance" "strapi_server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id = var.public_subnet_id
  
  # CHANGE 1: Use 'vpc_security_group_ids' for VPCs (security_groups is legacy)
  vpc_security_group_ids = [var.app_sg_id]

  root_block_device {
    volume_size = 20    # 20 GB Storage (Was 8 GB)
    volume_type = "gp3" # General Purpose SSD
  }

  # CHANGE 2: Wrap the script in a HEREDOC string (<<-EOF ... EOF)
  user_data = <<-EOF
    #!/bin/bash
    set -ex  # This ensures logs are visible in /var/log/cloud-init-output.log

    # 1. Update system and install required tools
    apt-get update -y
    apt-get install -y docker.io git

    # 2. Start and enable Docker service
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ubuntu

    # 3. Create a clean working directory
    mkdir -p /home/ubuntu/strapi-app
    cd /home/ubuntu/strapi-app

    # 4. Create the Dockerfile
    cat <<DOCKERFILE > Dockerfile
    FROM node:18

    # Set the working directory inside the container
    WORKDIR /srv/app

    # Install git
    RUN apt-get update && apt-get install -y git

    # CLONE STRATEGY: 
    # Clone directly into the current directory (.) to find package.json immediately
    RUN git clone https://github.com/sagarpatade/strapi-intern-task1.git .

    # Install dependencies
    RUN npm install

    # Build the Strapi admin panel
    RUN npm run build

    # Expose the default Strapi port
    EXPOSE 1337

    # Start Strapi in development mode
    CMD ["npm", "run", "develop"]
    DOCKERFILE

    # 5. Build the Docker Image
    # This might take 5-10 minutes depending on instance size
    docker build -t my-strapi-app .

    # 6. Run the Container
    docker run -d \
      --name strapi-container \
      --restart always \
      -p 1337:1337 \
      my-strapi-app
  EOF

  tags = {
    Name = "${var.environment}-strapi-server"
  }
}

# 3. CONNECT TO LOAD BALANCER
resource "aws_lb_target_group_attachment" "strapi_attach" {
  target_group_arn = var.target_group_arn
  target_id        = aws_instance.strapi_server.id
  port             = 1337
}

# ---------------------------------------------------------
# BASTION HOST RESOURCES (Add to bottom of main.tf)
# ---------------------------------------------------------

# 1. Bastion Security Group (The "Lobby Guard")
resource "aws_security_group" "bastion_sg" {
  name        = "bastion-security-group"
  description = "Allow SSH access"
  vpc_id = var.vpc_id  # <--- MAKE SURE THIS MATCHES YOUR VPC NAME

  # Inbound: Allow SSH from ANYWHERE
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
  
  # IMPORTANT: This must be the PUBLIC subnet ID
  subnet_id     = var.public_subnet_id 
  
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "Task4-Bastion-Host"
  }
}