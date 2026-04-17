# ──────────────────────────────────────────────────────────────
# Root Module – Orchestrates VPC, EC2 (Docker), and S3
# S3 stores images → EC2 serves the web app and fetches images
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

module "s3" {
  source = "./modules/s3"
}

module "ec2" {
  source        = "./modules/ec2"
  instance_type = var.instance_type
  vpc_id        = module.vpc.vpc_id
  subnet_id     = module.vpc.subnet_id
  docker_image  = var.docker_image
  s3_bucket_url = module.s3.bucket_regional_domain

  depends_on = [module.s3]
}
