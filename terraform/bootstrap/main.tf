# This file bootstraps the creation of s3 bucket for storing remote state and dynamodb table  for state locking
# To be run only once
data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "terraform_backend" {
  bucket = "${var.s3_bucket_name_prefix}-terraform-state-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name = "Terraform State Backend"
    Env  = var.environment
    App  = var.app_id
  }
}

resource "aws_s3_bucket_versioning" "terraform_backend_versioning" {
  bucket = aws_s3_bucket.terraform_backend.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_backend_encryption" {
  bucket = aws_s3_bucket.terraform_backend.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_backend_access" {
  bucket = aws_s3_bucket.terraform_backend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "${var.environment}-${var.app_id}-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "Terraform State Locks"
    Env  = var.environment
    App  = var.app_id
  }
}