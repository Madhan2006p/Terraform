output "bucket_name" {
  value = aws_s3_bucket.bucket.id
}

output "bucket_regional_domain" {
  description = "S3 bucket regional domain for accessing images"
  value       = "https://${aws_s3_bucket.bucket.bucket_regional_domain_name}"
}
