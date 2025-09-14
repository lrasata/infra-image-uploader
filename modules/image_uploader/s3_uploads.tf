locals {
  UPLOAD_FOLDER    = "uploads/"
  THUMBNAIL_FOLDER = "thumbnails/"
}

resource "aws_s3_bucket" "s3_bucket_uploads" {
  bucket = "${var.environment}-${var.uploads_bucket_name}"
}

# S3 uses Transfer Acceleration
# Clients connect to the nearest AWS CloudFront edge location instead. Data is then sent through AWS’s private backbone network to the S3 bucket’s region.
resource "aws_s3_bucket_accelerate_configuration" "uploads_accel" {
  count  = var.enable_transfer_acceleration ? 1 : 0
  bucket = aws_s3_bucket.s3_bucket_uploads.id
  status = "Enabled"
}

#  Block public access to the S3 bucket
resource "aws_s3_bucket_public_access_block" "s3_bucket_public_access" {
  bucket                  = aws_s3_bucket.s3_bucket_uploads.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
