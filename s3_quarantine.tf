resource "aws_s3_bucket" "s3_bucket_quarantine" {
  bucket = "${var.environment}-${var.quarantine_bucket_name}"
}

#  Block public access to the S3 bucket
resource "aws_s3_bucket_public_access_block" "quarantine_bucket_public_access" {
  bucket                  = aws_s3_bucket.s3_bucket_quarantine.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}