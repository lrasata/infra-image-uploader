data "aws_sns_topic" "bucketav_results" {
  name = "bucketav-FindingsTopic-lHaIfqGDNADm" # TODO this should be automatically fetched after stack creation of bucketAV from CloudFormation
}

resource "aws_sns_topic_subscription" "lambda" {
  topic_arn = data.aws_sns_topic.bucketav_results.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.process_uplaoded_file.arn
}

resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_uplaoded_file.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = data.aws_sns_topic.bucketav_results.arn
}