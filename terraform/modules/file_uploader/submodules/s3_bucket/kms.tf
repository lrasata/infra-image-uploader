# Define a KMS Key to be managed by the customer
resource "aws_kms_key" "s3_upload_key" {
  description             = "${var.environment}-s3-uploads-cmk"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  tags = {
    Environment = var.environment
    App         = var.app_id
  }
}

resource "aws_kms_alias" "s3_upload_alias" {
  name          = "alias/${var.environment}-file-uploads"
  target_key_id = aws_kms_key.s3_upload_key.key_id
}