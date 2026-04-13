variable "region" {
  description = "AWS region for all resources"
  type        = string
  default     = "ap-south-1"
}

variable "instance_type" {
  description = "EC2 instance type for the Docker host"
  type        = string
  default     = "t3.micro"
}

variable "docker_image" {
  description = "Docker image to deploy on the EC2 instance"
  type        = string
  default     = "nginx:alpine"
}
