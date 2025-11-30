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

output "uploads_bucket_kms_key_arn" {
  description = "KMS CMK ARN used for S3 SSE-KMS"
  value       = aws_kms_key.s3_cmk.arn
}

# output "uploads_bucket_acceleration_domain_name" {
#   description = "Acceleration domain name for S3 Transfer Acceleration"
#   value       = var.enable_transfer_acceleration ? aws_s3_bucket.uploads.accelerated_domain_name : null
# }