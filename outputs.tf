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

output "s3_image_bucket" {
  description = "S3 bucket URL for project images"
  value       = module.s3.bucket_regional_domain
}

output "app_url" {
  description = "Main application URL"
  value       = "http://${module.ec2.public_ip}"
}

output "profile_url" {
  description = "AutoServe Pro profile page URL"
  value       = "http://${module.ec2.public_ip}/madhan-profile/"
}
