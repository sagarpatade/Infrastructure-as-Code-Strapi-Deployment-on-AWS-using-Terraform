# 🚀 Infrastructure as Code: Strapi on AWS

This project automates the deployment of a **Strapi v4 Headless CMS** on AWS using **Terraform** and **Docker**.

## 🏗 Architecture
* **VPC:** Custom VPC with Public & Private Subnets.
* **Security:** Application runs in a Private Subnet (No Public IP).
* **Access:** Secure access via AWS Systems Manager (Session Manager).
* **Load Balancer:** Application Load Balancer (ALB) for traffic distribution.

## 🛠 Tech Stack
* **Cloud:** AWS (EC2, VPC, ALB, IAM)
* **IaC:** Terraform
* **Containerization:** Docker (Node 20 + Strapi v4)

## 🔧 How to Deploy
1.  Initialize Terraform: `terraform init`
2.  Plan deployment: `terraform plan`
3.  Apply changes: `terraform apply -auto-approve`
