# 1. The Application Load Balancer (ALB)
resource "aws_lb" "strapi_alb" {
  name               = "${var.environment}-alb"
  internal           = false # False = Internet Facing
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets = [var.public_subnet_id, var.public_subnet_2_id]
  
  # IMPORTANT: ALBs need subnets in different Availability Zones (AZs).
  # Since our task usually uses 1 region, we pass the subnets we have.
  # If Terraform errors asking for >1 AZ, we might need to adjust the networking modul

  enable_deletion_protection = false

  tags = {
    Name = "${var.environment}-alb"
  }
}

# 2. Target Group (The Guest List)
# This tracks the health of your Strapi App.
resource "aws_lb_target_group" "strapi_tg" {
  name        = "${var.environment}-tg"
  target_type = "instance"
  port        = 1337             # Strapi runs on Port 1337
  protocol    = "HTTP"
  vpc_id      = var.vpc_id

  # Health Check: Pings the server to make sure it's alive
  health_check {
    path                = "/" # Checks the homepage
    protocol            = "HTTP"
    matcher             = "200-404" # 200 (OK) or 404 (Not Found) means server is running
    interval            = 60
    timeout             = 30
    healthy_threshold   = 2
    unhealthy_threshold = 5
  }
}

# 3. Listener (The Ear)
# Listens on Port 80 (HTTP) from the internet and forwards to Strapi
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.strapi_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.strapi_tg.arn
  }
}