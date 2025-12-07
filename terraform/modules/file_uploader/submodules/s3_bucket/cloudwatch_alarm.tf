# ====================================================
# CloudWatch Alarm for failed uploads using S3 metrics
# ====================================================

# 4xx errors indicate failed client uploads
resource "aws_cloudwatch_metric_alarm" "failed_uploads_alarm" {
  alarm_name          = "${var.environment}-${var.app_id}-failed-uploads"
  alarm_description   = "Triggers if there are client-side failed S3 uploads (4xx errors)."
  namespace           = "AWS/S3"
  metric_name         = "4xxErrors"
  statistic           = "Sum"
  period              = 300 # 5 minutes
  evaluation_periods  = 1
  threshold           = 5 # triggers if at least 5 failed upload in period
  comparison_operator = "GreaterThanOrEqualToThreshold"

  dimensions = {
    BucketName  = aws_s3_bucket.uploads.bucket
    StorageType = "AllStorageTypes"
  }

  alarm_actions = [var.sns_topic_alert_arn] # SNS or other notification
}

# 5xx errors alarm for server-side errors (5xx)
resource "aws_cloudwatch_metric_alarm" "s3_5xx_errors_alarm" {
  alarm_name          = "${var.environment}-${var.app_id}-s3-5xx-errors"
  alarm_description   = "Triggers if there are server-side S3 errors (5xx)."
  namespace           = "AWS/S3"
  metric_name         = "5xxErrors"
  statistic           = "Sum"
  period              = 300 # 5 minutes
  evaluation_periods  = 1
  threshold           = 5
  comparison_operator = "GreaterThanOrEqualToThreshold"

  dimensions = {
    BucketName  = aws_s3_bucket.uploads.bucket
    StorageType = "AllStorageTypes"
  }

  alarm_actions = [var.sns_topic_alert_arn]
}