variable "environment" {}
variable "ami_id" {}
variable "instance_type" {}
variable "key_name" {}
variable "private_subnet_id" {}
variable "app_sg_id" {}
variable "target_group_arn" {}

variable "iam_instance_profile" {
  description = "IAM Profile name for SSM Session Manager"
  type        = string
}

variable "public_subnet_id" {
  description = "The ID of the Public Subnet for the Bastion Host"
  type        = string
}

variable "vpc_id" {
  description = "The VPC ID where resources are created"
  type        = string
}