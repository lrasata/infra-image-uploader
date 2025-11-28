# S3 bucket for uploads and thumbnails storage
resource "aws_s3_bucket" "uploads" {
  bucket = "${var.environment}-${var.app_id}-${var.uploads_bucket_name}"

  tags = {
    Name        = "${var.environment}-uploads-bucket"
    Environment = var.environment
    App         = var.app_id
    Description = "Bucket for storing uploaded files and geenrated thumbnails"
  }
}


# ============================================================================
# UPLOADS BUCKET CONFIGURATION
# ============================================================================
# Versioning
resource "aws_s3_bucket_versioning" "uploads_versioning" {
  bucket = aws_s3_bucket.uploads.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption with KMS
resource "aws_s3_bucket_server_side_encryption_configuration" "uploads_encryption" {
  bucket = aws_s3_bucket.uploads.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3_upload_key.arn
    }
  }
}

# Block all public access to uploads bucket
resource "aws_s3_bucket_public_access_block" "uploads_public_access" {
  bucket = aws_s3_bucket.uploads.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable CORS for presigned URL uploads from browsers
# Allows the web browser to make a PUT request directly to S3 using presigned url. S3 is the one handling the CORS preflight
resource "aws_s3_bucket_cors_configuration" "uploads_cors" {
  bucket = aws_s3_bucket.uploads.id

  cors_rule {
    allowed_methods = ["PUT", "GET", "HEAD"]
    allowed_origins = ["*"]
    allowed_headers = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }

  depends_on = [aws_s3_bucket_public_access_block.uploads_public_access]
}

# Optional: Enable S3 Transfer Acceleration for faster uploads
resource "aws_s3_bucket_accelerate_configuration" "uploads_acceleration" {
  count  = var.enable_transfer_acceleration ? 1 : 0
  bucket = aws_s3_bucket.uploads.id
  status = "Enabled"

  depends_on = [aws_s3_bucket_public_access_block.uploads_public_access]
}

#
# ============================================================================
# Logging target bucket
# ============================================================================
resource "aws_s3_bucket" "log_target" {
  bucket = "${var.environment}-${var.app_id}-s3-access-logs"
}

resource "aws_s3_bucket_versioning" "log_target_versioning" {
  bucket = aws_s3_bucket.log_target.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "log_target_block" {
  bucket = aws_s3_bucket.log_target.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "log_target_sse" {
  bucket = aws_s3_bucket.log_target.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
      # AWS-managed key
    }
  }
}

# Logging Target Bucket ACL (required for S3 logs)
resource "aws_s3_bucket_acl" "log_target_acl" {
  bucket = aws_s3_bucket.log_target.id
  acl    = "log-delivery-write"
}

# Source Bucket (where uploads go), with logging configured directly
resource "aws_s3_bucket_logging" "uploads_logging" {
  bucket        = aws_s3_bucket.uploads.id
  target_bucket = aws_s3_bucket.log_target.id
  target_prefix = "${var.environment}-${var.app_id}-uploads-access-logs/"
}