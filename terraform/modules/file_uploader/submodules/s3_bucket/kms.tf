resource "aws_kms_key" "s3_cmk" {
  description         = "CMK for S3 uploads and access logs"
  enable_key_rotation = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Allow root account full access
      {
        Sid    = "AllowRootAccount"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
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

      # Allow S3 logging to use the key
      {
        Sid    = "AllowS3Logging"
        Effect = "Allow"
        Principal = {
          Service = "logging.s3.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

data "aws_caller_identity" "current" {}
