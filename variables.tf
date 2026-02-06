variable "region" {
  default = "us-east-1"
}
variable "environment" {
  description = "dev or prod"
}
variable "vpc_cidr" {}
variable "public_subnet_cidr" {}
variable "private_subnet_cidr" {}

variable "ami_id" {
  description = "AMI ID for the EC2 Instance"
}

variable "instance_type" {
  description = "Instance Type (e.g., t2.medium)"
}