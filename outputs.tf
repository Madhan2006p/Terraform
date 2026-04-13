output "instance_ip" {
  description = "Public IP of the Docker host — access the app at http://<this-ip>"
  value       = module.ec2.public_ip
}

output "instance_dns" {
  description = "Public DNS of the Docker host"
  value       = module.ec2.public_dns
}

output "instance_id" {
  description = "EC2 Instance ID"
  value       = module.ec2.instance_id
}

output "s3_website_url" {
  description = "S3 static website URL"
  value       = module.s3.website_url
}
