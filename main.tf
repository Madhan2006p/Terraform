# ──────────────────────────────────────────────────────────────
# Root Module – Orchestrates VPC, EC2 (Docker), and S3
# ──────────────────────────────────────────────────────────────

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

module "vpc" {
  source = "./modules/vpc"
}

module "ec2" {
  source        = "./modules/ec2"
  instance_type = var.instance_type
  vpc_id        = module.vpc.vpc_id
  subnet_id     = module.vpc.subnet_id
  docker_image  = var.docker_image
}

module "s3" {
  source = "./modules/s3"
}
