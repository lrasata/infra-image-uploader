# If var.use_bucketav == true i.e BucketAV is enabled
# then we trigger lambda for processing uploaded file togenerate thumbnail and update DynamoDB AFTER the file is successfully scanned
# and is tagged "clean"
data "aws_sns_topic" "bucketav_results" {
  count = var.use_bucketav ? 1 : 0
  name  = var.bucketav_sns_findings_topic_name
}

resource "aws_sns_topic_subscription" "lambda" {
  count     = var.use_bucketav ? 1 : 0
  topic_arn = data.aws_sns_topic.bucketav_results[count.index].arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.process_uploaded_file.arn

  depends_on = [aws_lambda_permission.allow_sns]
}

resource "aws_lambda_permission" "allow_sns" {
  count         = var.use_bucketav ? 1 : 0
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_uploaded_file.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = data.aws_sns_topic.bucketav_results[count.index].arn
}

#########################################################################################
# If BucketAV is disabled
# then there is no virus scan
# Lambda for processing uploaded file is directly triggered when notified by S3 bucket notification that an object has been created
resource "aws_lambda_permission" "allow_s3_to_invoke_process_uploaded_file" {
  count         = var.use_bucketav ? 0 : 1
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_uploaded_file.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.s3_bucket_uploads.arn
}

resource "aws_s3_bucket_notification" "source_notification" {
  count  = var.use_bucketav ? 0 : 1
  bucket = aws_s3_bucket.s3_bucket_uploads.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.process_uploaded_file.arn
    events              = ["s3:ObjectCreated:*"]
    # Add filter so only objects under "uploads/" trigger the lambda
    filter_prefix = local.UPLOAD_FOLDER
  }

  depends_on = [aws_lambda_function.process_uploaded_file, aws_lambda_permission.allow_s3_to_invoke_process_uploaded_file]
}