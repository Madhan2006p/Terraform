variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "vpc_id" {
  description = "VPC ID where EC2 security group is created"
  type        = string
}

variable "subnet_id" {
  description = "Public subnet ID where EC2 is launched"
  type        = string
}

variable "docker_image" {
  description = "Docker image to deploy on the EC2 instance"
  type        = string
  default     = "nginx:alpine"
}
