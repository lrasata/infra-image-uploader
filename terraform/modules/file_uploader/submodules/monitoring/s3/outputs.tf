output "s3_metrics" {
  value = {
    all_requests = aws_s3_bucket_metric.all_requests.name
  }
}

output "alarm_4xx" {
  value = aws_cloudwatch_metric_alarm.s3_4xx_errors.arn
}

output "alarm_5xx" {
  value = aws_cloudwatch_metric_alarm.s3_5xx_errors.arn
}
