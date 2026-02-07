# main.tf (Root)

# 1. NETWORKING MODULE (The Foundation)
module "networking" {
  source = "./modules/networking"

  # Inputs from terraform.tfvars
  region              = var.region
  environment         = var.environment
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
}

# 2. SECURITY MODULE (The Firewalls & Keys)
module "security" {
  source = "./modules/security"

  environment = var.environment
  
  # DEPENDENCY: Needs the VPC ID created in step 1
  vpc_id      = module.networking.vpc_id
}

# 3. LOAD BALANCER MODULE (The Traffic Manager)
# CHECK: Ensure your folder is named "modules/loadbalancer" or "modules/loadbalancing"
# If your folder is named "loadbalancing", change the source line below to "./modules/loadbalancing"
module "loadbalancer" {
  source = "./modules/loadbalancer" 

  environment = var.environment
  vpc_id      = module.networking.vpc_id
  
  # DEPENDENCY: Needs the Security Group created in step 2
  alb_sg_id   = module.security.alb_sg_id

  # DEPENDENCY: Needs Subnets created in step 1
  public_subnet_id     = module.networking.public_subnet_id    # Zone A
  public_subnet_2_id   = module.networking.public_subnet_2_id
  private_subnet_id    = module.networking.private_subnet_id
}

# 4. COMPUTE MODULE (The Application)
module "compute" {
  source = "./modules/compute"

  environment      = var.environment
  ami_id           = var.ami_id
  instance_type    = var.instance_type
  
  # DEPENDENCY: Needs the Key and SG from Phase 2
  key_name         = module.security.key_name
  app_sg_id        = module.security.app_sg_id
  
  # DEPENDENCY: Needs the Private Subnet from Phase 1
  private_subnet_id = module.networking.private_subnet_id
  
  # DEPENDENCY: Needs the Target Group from Phase 3
  target_group_arn = module.loadbalancer.target_group_arn # Note: Ensure module name matches step 3 name

  vpc_id           = module.networking.vpc_id
  public_subnet_id = module.networking.public_subnet_id

  # --- [FIX IS HERE] ---
  # We must pass the SSM Profile from Security to Compute
  iam_instance_profile = module.security.ssm_profile_name
}