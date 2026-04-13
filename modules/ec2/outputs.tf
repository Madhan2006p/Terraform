output "public_ip" {
  description = "Public IP address of the Docker host EC2 instance"
  value       = aws_instance.web.public_ip
}

output "instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.web.id
}

output "public_dns" {
  description = "Public DNS name of the Docker host EC2 instance"
  value       = aws_instance.web.public_dns
}
