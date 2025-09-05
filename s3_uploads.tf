resource "aws_s3_bucket" "s3_bucket_uploads" {
  bucket = "${var.environment}-${var.uploads_bucket_name}"
}

#  Block public access to the S3 bucket
resource "aws_s3_bucket_public_access_block" "s3_bucket_public_access" {
  bucket                  = aws_s3_bucket.s3_bucket_uploads.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


# s3 permission to invoke virus scan lambda
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3InvokeLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.virus_scan.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.s3_bucket_uploads.arn
}

# Attach the Lambda as a notification for all object creations
resource "aws_s3_bucket_notification" "upload_bucket_notification" {
  bucket = aws_s3_bucket.s3_bucket_uploads.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.virus_scan.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [
    aws_lambda_permission.allow_s3
  ]
}

