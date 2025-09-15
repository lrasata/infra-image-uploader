output "api_gateway_invoke_url" {
  description = "Public URL for invoking the API Gateway"
  value       = "https://${var.api_image_upload_domain_name}/upload-url"
}

output "uploads_bucket_id" {
  description = "The S3 uploads bucket ID (name)"
  value       = aws_s3_bucket.s3_bucket_uploads.id
}

output "uploads_bucket_arn" {
  description = "The ARN of the S3 uploads bucket"
  value       = aws_s3_bucket.s3_bucket_uploads.arn
}

output "uploads_bucket_regional_domain_name" {
  description = "The regional domain name of the S3 bucket (for CloudFront origin)"
  value       = aws_s3_bucket.s3_bucket_uploads.bucket_regional_domain_name
}