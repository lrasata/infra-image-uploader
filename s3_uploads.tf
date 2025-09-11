locals {
  UPLOAD_FOLDER    = "uploads/"
  THUMBNAIL_FOLDER = "thumbnails/"
}

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

resource "aws_lambda_permission" "allow_s3_to_invoke_process_uploaded_file" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_uplaoded_file.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.s3_bucket_uploads.arn
}

resource "aws_s3_bucket_notification" "source_notification" {
  bucket = aws_s3_bucket.s3_bucket_uploads.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.process_uplaoded_file.arn
    events              = ["s3:ObjectCreated:*"]
    # Add filter so only objects under "uploads/" trigger the lambda
    filter_prefix = local.UPLOAD_FOLDER
  }



  depends_on = [aws_lambda_function.process_uplaoded_file, aws_lambda_permission.allow_s3_to_invoke_process_uploaded_file]
}
