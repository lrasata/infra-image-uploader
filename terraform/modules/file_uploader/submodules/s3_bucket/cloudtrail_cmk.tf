resource "aws_kms_key" "cloudtrail_cmk" {
  description             = "CMK for CloudTrail logs encryption"
  deletion_window_in_days = 30

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # Root account full access
      {
        Sid       = "AllowRootAccount"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },

      # Allow GitHub Actions role to manage the key
      {
        Sid    = "AllowGithubActions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::387836084035:role/gitHubFileUploader"
        }
        Action = [
          "kms:*" # full key management actions including PutKeyPolicy
        ]
        Resource = "*"
      },

      # Allow CloudTrail to encrypt logs
      {
        Sid       = "AllowCloudTrailService"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_kms_alias" "cloudtrail_cmk_alias" {
  name          = "alias/${var.environment}-${var.app_id}-cloudtrail-cmk"
  target_key_id = aws_kms_key.cloudtrail_cmk.id
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_target_sse" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.cloudtrail_cmk.arn
    }
  }
}
