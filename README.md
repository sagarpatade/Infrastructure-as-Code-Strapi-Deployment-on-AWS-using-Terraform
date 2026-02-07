# 🚀 Infrastructure as Code: Strapi Deployment on AWS

This project automates the deployment of a **Strapi v4 Headless CMS** on AWS using **Terraform** and **Docker**.

It provisions a secure, production-ready infrastructure with a custom VPC, Public/Private subnet separation, and an Application Load Balancer.



## 🏗 Architecture Overview

The infrastructure is designed with security and scalability in mind:

* **VPC:** A custom Virtual Private Cloud spanning 2 Availability Zones.
* **Networking:**
    * **Public Subnets:** Host the Application Load Balancer (ALB) and NAT Gateway.
    * **Private Subnets:** Host the actual Strapi Application Server (EC2). The server has **no public IP** and is not directly accessible from the internet.
* **Security:**
    * **Strict Security Groups:** The App Server only accepts traffic from the Load Balancer.
    * **SSM Session Manager:** SSH ports (22) are closed. Access is managed via AWS Systems Manager for secure, passwordless auditing.
* **Compute:** An EC2 instance running Docker, with a custom initialization script that installs Node 20 and builds Strapi from source.

## 🛠 Tech Stack

* **Cloud Provider:** AWS (EC2, VPC, ALB, IAM, SSM, NAT Gateway)
* **IaC Tool:** Terraform
* **Containerization:** Docker
* **Application:** Strapi v4 (Node.js 20 Bullseye)

---

## 📋 Prerequisites

Before running this project, ensure you have:

1.  **AWS Account** (and access keys with permissions for EC2, VPC, IAM).
2.  **Terraform installed** (v1.0+).
3.  **AWS CLI installed** and configured (`aws configure`).

---

## 🚀 How to Deploy

### 1. Clone the Repository
```bash
git clone [https://github.com/sagarpatade/Infrastructure-as-Code-Strapi-Deployment-on-AWS-using-Terraform.git](https://github.com/sagarpatade/Infrastructure-as-Code-Strapi-Deployment-on-AWS-using-Terraform.git)
cd Infrastructure-as-Code-Strapi-Deployment-on-AWS-using-Terraform
2. Configure Variables
Create a terraform.tfvars file in the root directory to customize your deployment (optional, or use defaults):

Terraform

region      = "us-east-1"
environment = "dev"
key_name    = "my-aws-key" # Ensure this key exists in your AWS Console
3. Initialize & Apply
Bash

# Initialize Terraform modules
terraform init

# Review the deployment plan
terraform plan

# Deploy infrastructure (Takes ~5-10 mins)
terraform apply -auto-approve
4. Access the Application
Wait about 8-12 minutes after Terraform finishes. The server needs time to install Docker, build the Strapi admin panel, and start the container.

Terraform will output a value named alb_dns_name.

Copy and paste that URL into your browser:

http://<your-load-balancer-dns>.us-east-1.elb.amazonaws.com

You should see the Strapi Welcome Page to create your first admin user.

🐛 Troubleshooting & Known Fixes
This repository includes specific patches for Strapi v4 + Node 20 compatibility:

1. The "502 Bad Gateway" (Initial Wait)
Cause: The server is still building the Docker image.

Fix: Wait 10 minutes. You can check progress by connecting via AWS Console > Connect > Session Manager and running:

Bash

sudo tail -f /var/log/cloud-init-output.log
2. Node 20 & minimatch Crash
Issue: Recent Strapi dependencies require Node 18/20, but standard Ubuntu repositories have older Node versions.

Fix: The user_data script explicitly uses a node:20-bullseye Docker base image.

3. The --host Flag Error
Issue: Strapi v4.25+ deprecated the command line flag --host 0.0.0.0, causing containers to crash on startup.

Fix: We removed the flag and implemented environment variable configuration in the Dockerfile:

Dockerfile

ENV HOST=0.0.0.0
CMD ["npm", "run", "develop"]
🧹 Cleanup
To avoid ongoing AWS charges, destroy the infrastructure when you are done:

Bash

terraform destroy -auto-approve
📂 Project Structure
├── main.tf                 # Root configuration & module calls
├── variables.tf            # Global variables
├── outputs.tf              # Outputs (Load Balancer URL)
├── modules/
│   ├── networking/         # VPC, Subnets, Internet Gateway, NAT
│   ├── security/           # Security Groups, IAM Roles, SSM Profile
│   ├── compute/            # EC2 Instance, User Data Script (Docker/Strapi)
│   └── loadbalancing/      # Application Load Balancer, Target Groups
└── README.md
