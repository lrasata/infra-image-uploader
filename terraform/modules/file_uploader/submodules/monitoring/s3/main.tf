#############################################
# 1. Native S3 Request Metrics
#############################################

resource "aws_s3_bucket_metric" "all_requests" {
  bucket = var.bucket_id
  name   = "AllRequests"
}

#############################################
# 2. Alarm: 4xx Errors (Client failures)
#############################################

resource "aws_cloudwatch_metric_alarm" "s3_4xx_errors" {
  alarm_name          = "${var.bucket_name}-4xx-errors"
  alarm_description   = "Frequent S3 4xx client-side errors (failed uploads)."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 5
  period              = 300
  metric_name         = "4xxErrors"
  namespace           = "AWS/S3"
  statistic           = "Sum"

  dimensions = {
    BucketName  = var.bucket_name
    StorageType = "AllStorageTypes"
  }

  alarm_actions = [var.sns_topic_arn]
}

#############################################
# 3. Alarm: 5xx Errors (Server failures)
#############################################

resource "aws_cloudwatch_metric_alarm" "s3_5xx_errors" {
  alarm_name          = "${var.bucket_name}-5xx-errors"
  alarm_description   = "Frequent S3 5xx server-side errors."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 1
  period              = 300
  metric_name         = "5xxErrors"
  namespace           = "AWS/S3"
  statistic           = "Sum"

  dimensions = {
    BucketName  = var.bucket_name
    StorageType = "AllStorageTypes"
  }

  alarm_actions = [var.sns_topic_arn]
}


#############################################
# Dashboard
#############################################
resource "aws_cloudwatch_dashboard" "s3_monitoring" {
  dashboard_name = "${var.bucket_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/S3", "BucketSizeBytes", "BucketName", var.bucket_name, "StorageType", "StandardStorage"],
            ["AWS/S3", "NumberOfObjects", "BucketName", var.bucket_name, "StorageType", "AllStorageTypes"]
          ]
          period      = 86400
          stat        = "Average"
          title       = "Bucket Size & Object Count"
          region      = var.region
          view        = "timeSeries"
          annotations = {}
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/S3", "S3ObjectCreated", "BucketName", var.bucket_name, "StorageType", "AllStorageTypes"],
            ["AWS/S3", "S3FailedUploads", "BucketName", var.bucket_name, "StorageType", "AllStorageTypes"],
            ["AWS/S3", "S3EventNotificationsSent", "BucketName", var.bucket_name, "StorageType", "AllStorageTypes"]
          ]
          period      = 300
          stat        = "Sum"
          title       = "Upload & Event Metrics"
          region      = var.region
          view        = "timeSeries"
          annotations = {}
        }
      }
    ]
  })
}
