# ============================================================================
# Logging target bucket - S3 access logs
# ============================================================================
resource "aws_s3_bucket" "log_target" {
  bucket = "${var.environment}-${var.app_id}-s3-access-logs"
}

resource "aws_s3_bucket_ownership_controls" "log_target_ownership" {
  bucket = aws_s3_bucket.log_target.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "log_target_versioning" {
  bucket = aws_s3_bucket.log_target.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "log_target_block" {
  bucket = aws_s3_bucket.log_target.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "log_target_policy" {
  bucket = aws_s3_bucket.log_target.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "logging.s3.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.log_target.arn}/*"
      }
    ]
  })
}

resource "aws_s3_bucket_logging" "uploads_logging" {
  bucket        = aws_s3_bucket.uploads.id
  target_bucket = aws_s3_bucket.log_target.id
  target_prefix = "${var.environment}-${var.app_id}-uploads-access-logs/"

  depends_on = [
    aws_s3_bucket_policy.log_target_policy,
    aws_s3_bucket_ownership_controls.log_target_ownership
  ]
}

# ============================================================================
# Logging target bucket - CloudTrail
# ============================================================================
resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket = "${var.environment}-${var.app_id}-cloudtrail-logs"
}

resource "aws_s3_bucket_public_access_block" "cloudtrail_logs_block" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "cloudtrail_logs_ownership" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "cloudtrail_logs_versioning" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "cloudtrail_logs_policy" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AWSCloudTrailWrite"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = ["s3:PutObject"]
        Resource  = "${aws_s3_bucket.cloudtrail_logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" }
        }
      },
      {
        Sid       = "AWSCloudTrailBucketAclCheck"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = ["s3:GetBucketAcl"]
        Resource  = aws_s3_bucket.cloudtrail_logs.arn
      }
    ]
  })
}

# ============================================================================
# CloudWatch Log Group for CloudTrail
# ============================================================================
resource "aws_cloudwatch_log_group" "s3_logs" {
  name              = "/aws/cloudtrail/${var.environment}-${var.app_id}-s3"
  retention_in_days = 30
}

# IAM Role for CloudTrail to CloudWatch
resource "aws_iam_role" "cloudtrail_to_cw" {
  name = "${var.environment}-${var.app_id}-cloudtrail-to-cw"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

# Corrected IAM Policy: exact ARN format required by CloudTrail
resource "aws_iam_role_policy" "cloudtrail_to_cw_policy" {
  name = "${var.environment}-${var.app_id}-cloudtrail-to-cw-policy"
  role = aws_iam_role.cloudtrail_to_cw.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:${aws_cloudwatch_log_group.s3_logs.name}:*"
      }
    ]
  })
}

# ============================================================================
# CloudTrail Trail
# ============================================================================
resource "aws_cloudtrail" "s3_data_trail" {
  name                          = "${var.environment}-${var.app_id}-s3-data-events"
  include_global_service_events = false
  is_multi_region_trail         = false
  s3_bucket_name                = aws_s3_bucket.cloudtrail_logs.bucket
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail_to_cw.arn
  kms_key_id                    = aws_kms_key.cloudtrail_cmk.arn
  enable_log_file_validation    = true

  event_selector {
    read_write_type = "WriteOnly"
    data_resource {
      type   = "AWS::S3::Object"
      values = ["${aws_s3_bucket.uploads.arn}/"]
    }
  }
}

# ============================================================================
# CloudWatch Metric Filter and Alarm
# ============================================================================
resource "aws_cloudwatch_log_metric_filter" "failed_s3_uploads" {
  name           = "FailedS3Uploads"
  log_group_name = aws_cloudwatch_log_group.s3_logs.name

  pattern = "{ ($.eventSource = \"s3.amazonaws.com\") && ($.eventName = \"PutObject\") && ($.errorCode = \"*\") }"

  metric_transformation {
    name      = "FailedUploads"
    namespace = "Custom/S3"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "failed_uploads_alarm" {
  alarm_name          = "${var.environment}-${var.app_id}-failed-uploads"
  alarm_description   = "Triggers if more than 5 S3 uploads fail in 5 minutes."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  period              = 300 # 5 minutes
  metric_name         = aws_cloudwatch_log_metric_filter.failed_s3_uploads.metric_transformation[0].name
  namespace           = aws_cloudwatch_log_metric_filter.failed_s3_uploads.metric_transformation[0].namespace
  statistic           = "Sum"
  threshold           = 5

  alarm_actions = [var.sns_topic_alert_arn]
}