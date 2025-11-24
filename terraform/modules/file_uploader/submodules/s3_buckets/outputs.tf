output "uploads_bucket_id" {
  description = "ID (name) of the uploads S3 bucket"
  value       = aws_s3_bucket.uploads.id
}

output "uploads_bucket_arn" {
  description = "ARN of the uploads S3 bucket"
  value       = aws_s3_bucket.uploads.arn
}

output "uploads_bucket_regional_domain_name" {
  description = "Regional domain name of the uploads bucket (for CloudFront)"
  value       = aws_s3_bucket.uploads.bucket_regional_domain_name
}

output "uploads_bucket_acceleration_domain_name" {
  description = "Acceleration domain name for S3 Transfer Acceleration"
  value       = var.enable_transfer_acceleration ? aws_s3_bucket.uploads.accelerated_domain_name : null
}

output "thumbnails_bucket_id" {
  description = "ID (name) of the thumbnails S3 bucket"
  value       = aws_s3_bucket.thumbnails.id
}

output "thumbnails_bucket_arn" {
  description = "ARN of the thumbnails S3 bucket"
  value       = aws_s3_bucket.thumbnails.arn
}

output "uploads_folder_prefix" {
  description = "S3 key prefix for uploaded files"
  value       = local.uploads_folder
}

output "thumbnails_folder_prefix" {
  description = "S3 key prefix for thumbnail files"
  value       = local.thumbnails_folder
}