# Terraform Docker Deployment – Documentation

> **Automated infrastructure provisioning and containerized application deployment on AWS using Terraform and Jenkins.**

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Directory Structure](#directory-structure)
4. [Prerequisites](#prerequisites)
5. [Terraform Configuration](#terraform-configuration)
6. [Manual Deployment](#manual-deployment)
7. [Jenkins Pipeline Setup](#jenkins-pipeline-setup)
8. [GitHub Repository Setup](#github-repository-setup)
9. [Verification](#verification)
10. [Cleanup](#cleanup)
11. [Troubleshooting](#troubleshooting)

---

## Project Overview

This project uses **Terraform** (Infrastructure as Code) to provision AWS resources and deploy a **Dockerized web application** automatically. A **Jenkins CI/CD pipeline** orchestrates the entire workflow — from code checkout to infrastructure provisioning to container deployment.

### What Gets Created

| Resource | Description |
|----------|-------------|
| **VPC** | Custom VPC (`10.0.0.0/16`) with DNS support |
| **Subnet** | Public subnet (`10.0.1.0/24`) with auto-assign public IP |
| **Internet Gateway** | Enables internet access for the VPC |
| **Route Table** | Routes all outbound traffic through the IGW |
| **Security Group** | Allows HTTP (80), HTTPS (443), SSH (22), App (8080) |
| **EC2 Instance** | Amazon Linux 2 with Docker + Docker Compose |
| **Docker Container** | Nginx container serving a custom web page |
| **S3 Bucket** | Static website hosting (bonus) |

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                      AWS Cloud                          │
│  ┌───────────────────────────────────────────────────┐  │
│  │              VPC (10.0.0.0/16)                    │  │
│  │  ┌─────────────────────────────────────────────┐  │  │
│  │  │     Public Subnet (10.0.1.0/24)             │  │  │
│  │  │  ┌───────────────────────────────────────┐  │  │  │
│  │  │  │        EC2 Instance (t3.micro)        │  │  │  │
│  │  │  │  ┌─────────────────────────────────┐  │  │  │  │
│  │  │  │  │    Docker Engine                │  │  │  │  │
│  │  │  │  │  ┌───────────────────────────┐  │  │  │  │  │
│  │  │  │  │  │  Nginx Container (:80)    │  │  │  │  │  │
│  │  │  │  │  │  Custom HTML + Config     │  │  │  │  │  │
│  │  │  │  │  └───────────────────────────┘  │  │  │  │  │
│  │  │  │  └─────────────────────────────────┘  │  │  │  │
│  │  │  └───────────────────────────────────────┘  │  │  │
│  │  └─────────────────────────────────────────────┘  │  │
│  │              Internet Gateway                     │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
          │                            │
    ┌─────┘                            └─────┐
    │  Jenkins (CI/CD)              Browser   │
    │  terraform plan/apply         http://IP │
    └─────────────────────────────────────────┘
```

---

## Directory Structure

```
terraform-webapp/
├── main.tf                    # Root module — orchestrates all sub-modules
├── provider.tf                # AWS provider configuration
├── variables.tf               # Input variables (region, instance_type, docker_image)
├── outputs.tf                 # Output values (IP, DNS, S3 URL)
├── terraform.tfvars           # Variable values (gitignored)
├── terraform.tfvars.example   # Template for tfvars (safe to commit)
├── Jenkinsfile                # CI/CD pipeline definition
├── .gitignore                 # Git exclusions for state & secrets
│
└── modules/
    ├── vpc/
    │   ├── main.tf            # VPC, Subnet, IGW, Route Table
    │   └── outputs.tf         # vpc_id, subnet_id, igw_id
    │
    ├── ec2/
    │   ├── main.tf            # EC2 instance with Docker + container
    │   ├── variables.tf       # instance_type, vpc_id, subnet_id, docker_image
    │   └── outputs.tf         # public_ip, public_dns, instance_id
    │
    └── s3/
        ├── main.tf            # S3 bucket with static website
        └── outputs.tf         # bucket_name, website_url
```

---

## Prerequisites

### Local Machine
- **Terraform** ≥ 1.3.0 → [Install Guide](https://developer.hashicorp.com/terraform/install)
- **AWS CLI** configured → `aws configure`
- **Git** for version control

### AWS
- An **AWS Account** with programmatic access
- **IAM User** with permissions for: `EC2`, `VPC`, `S3`, `IAM`
- **Access Key ID** and **Secret Access Key**

### Jenkins (for CI/CD)
- Jenkins 2.x+ installed and running
- Plugins required:
  - **Pipeline** (workflow-aggregator)
  - **AWS Credentials** (aws-credentials)
  - **Git** (git)
- Terraform binary available on Jenkins agent's `$PATH`

---

## Terraform Configuration

### Provider Setup

The AWS provider is configured in `provider.tf`:

```hcl
provider "aws" {
  region = var.region   # Default: ap-south-1
}
```

AWS credentials are resolved from environment variables or `~/.aws/credentials`.

### Input Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `region` | `ap-south-1` | AWS region |
| `instance_type` | `t3.micro` | EC2 instance size |
| `docker_image` | `nginx:alpine` | Container image to deploy |

### Key Design Decisions

1. **Modular structure** — VPC, EC2, and S3 are separate reusable modules
2. **Docker via user_data** — Docker and the container are installed on first boot using EC2 user data (cloud-init)
3. **Docker Compose** — Container orchestration uses Docker Compose for reproducibility and easy scaling
4. **Health checks** — The Nginx container includes a `/health` endpoint for monitoring

---

## Manual Deployment

### Step 1: Clone the Repository

```bash
git clone https://github.com/<your-username>/terraform-webapp.git
cd terraform-webapp
```

### Step 2: Configure Variables

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your preferred values
```

### Step 3: Configure AWS Credentials

```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="ap-south-1"
```

### Step 4: Initialize Terraform

```bash
terraform init
```

Expected output:
```
Terraform has been successfully initialized!
```

### Step 5: Validate Configuration

```bash
terraform validate
```

### Step 6: Preview Changes

```bash
terraform plan
```

Review the plan output to ensure the expected resources will be created.

### Step 7: Apply Configuration

```bash
terraform apply -auto-approve
```

This will:
1. Create the VPC and networking stack
2. Launch an EC2 instance
3. Install Docker on the instance
4. Pull the Nginx image and start the container
5. Create the S3 static website

### Step 8: Access the Application

```bash
# Get the public IP
terraform output instance_ip

# Open in browser
# http://<instance_ip>
```

> **Note**: It takes 2-3 minutes after `apply` for the user data script to finish installing Docker and starting the container.

---

## Jenkins Pipeline Setup

### Step 1: Install Required Plugins

In Jenkins → Manage Jenkins → Manage Plugins, install:
- **Pipeline**
- **AWS Credentials**
- **Git**

### Step 2: Add AWS Credentials

1. Go to **Manage Jenkins → Manage Credentials**
2. Add credentials:
   - **Kind**: AWS Credentials
   - **ID**: `aws-credentials`
   - **Access Key ID**: Your AWS Access Key
   - **Secret Access Key**: Your AWS Secret Key
3. Click **Save**

### Step 3: Install Terraform on Jenkins Agent

```bash
# On the Jenkins server/agent
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum install -y terraform
terraform --version
```

### Step 4: Create the Pipeline Job

1. **New Item** → Enter name `terraform-docker-deploy` → Select **Pipeline**
2. Under **Pipeline**:
   - **Definition**: Pipeline script from SCM
   - **SCM**: Git
   - **Repository URL**: `https://github.com/<your-username>/terraform-webapp.git`
   - **Branch**: `*/main`
   - **Script Path**: `terraform-webapp/Jenkinsfile`
3. Click **Save**

### Step 5: Run the Pipeline

1. Click **Build with Parameters**
2. Select ACTION:
   - `plan` — Preview changes only
   - `apply` — Create/update infrastructure
   - `destroy` — Tear down all resources
3. Set `INSTANCE_TYPE` and `DOCKER_IMAGE` as needed
4. Click **Build**

### Pipeline Stages

```
Checkout → Init → Validate → Format Check → Plan → Approval → Apply/Destroy → Outputs
```

| Stage | Description |
|-------|-------------|
| **Checkout** | Pulls latest code from GitHub |
| **Terraform Init** | Downloads providers and initializes modules |
| **Terraform Validate** | Checks syntax and configuration validity |
| **Format Check** | Verifies HCL formatting standards |
| **Terraform Plan** | Generates execution plan |
| **Approval** | Manual approval gate (apply/destroy only) |
| **Terraform Apply** | Provisions infrastructure and deploys container |
| **Terraform Destroy** | Tears down all resources |
| **Show Outputs** | Displays instance IP, DNS, and app URL |

---

## GitHub Repository Setup

### Step 1: Initialize Git

```bash
cd terraform-webapp
git init
git add .
git commit -m "Initial commit: Terraform Docker deployment"
```

### Step 2: Create GitHub Repository

1. Go to [github.com/new](https://github.com/new)
2. Repository name: `terraform-webapp`
3. Set to **Private** (contains infrastructure code)
4. Do NOT initialize with README (we already have files)

### Step 3: Push Code

```bash
git remote add origin https://github.com/<your-username>/terraform-webapp.git
git branch -M main
git push -u origin main
```

### Step 4: Configure Webhook (Optional)

For automatic Jenkins triggers on push:

1. Go to GitHub repo → **Settings → Webhooks → Add webhook**
2. **Payload URL**: `http://<jenkins-url>/github-webhook/`
3. **Content type**: `application/json`
4. **Events**: Just the push event
5. Click **Add webhook**

---

## Verification

### Check EC2 Instance

```bash
# Via AWS CLI
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=Terraform-DockerHost" \
  --query 'Reservations[].Instances[].[InstanceId,PublicIpAddress,State.Name]'
```

### Check Docker Container (SSH into instance)

```bash
ssh -i your-key.pem ec2-user@<instance-ip>

# Check container status
docker ps
# Expected: terraform-webapp container running

# Check container logs
docker logs terraform-webapp

# Test health endpoint
curl http://localhost/health
# Expected: OK
```

### Test Application

```bash
# From local machine
curl http://<instance-ip>
# Should return the HTML page

# Or open in browser
# http://<instance-ip>
```

---

## Cleanup

### Destroy All Resources

```bash
terraform destroy -auto-approve
```

Or via Jenkins pipeline with `ACTION = destroy`.

### Verify Cleanup

```bash
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=Terraform-DockerHost" \
  --query 'Reservations[].Instances[].[InstanceId,State.Name]'
# Should show "terminated"
```

---

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| `terraform init` fails | Check internet connectivity and AWS credentials |
| EC2 instance created but app not accessible | Wait 2-3 min for user data to complete; check security group rules |
| Container not running | SSH into instance, run `docker logs terraform-webapp` |
| Jenkins pipeline fails at Init | Ensure Terraform is installed on Jenkins agent |
| "InvalidAMIID" error | AMI availability varies by region; ensure `ap-south-1` is used |
| S3 bucket name conflict | S3 bucket names are globally unique; change the name in `modules/s3/main.tf` |

### Useful Commands

```bash
# Check user data execution log (on EC2)
sudo cat /var/log/cloud-init-output.log

# Restart the container
cd /opt/webapp && docker-compose restart

# Force re-deploy
cd /opt/webapp && docker-compose down && docker-compose up -d

# Check Terraform state
terraform state list
terraform state show module.ec2.aws_instance.web
```

---

## License

This project is for educational/organizational use.
