#############################################
# CloudWatch Dashboard
#############################################
resource "aws_cloudwatch_dashboard" "dynamodb_writer" {
  dashboard_name = "${var.table_name}-writer-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      # Writer throughput & errors (custom emitted metrics)
      {
        "type" : "metric",
        "x" : 0,
        "y" : 0,
        "width" : 12,
        "height" : 6,
        "properties" : {
          "region" : var.region,
          "title" : "Writer Throughput & Errors",
          "metrics" : [
            ["Custom/MetadataWriter", "DynamoWrites", "TableName", var.table_name, { stat : "Sum" }],
            ["Custom/MetadataWriter", "DynamoWriteFailed", "TableName", var.table_name, { stat : "Sum" }],
            ["Custom/MetadataWriter", "DynamoLatency", "TableName", var.table_name, { stat : "Average" }]
          ],
          "stat" : "Sum",
          "period" : 300
        }
      },

      # Native DynamoDB metrics
      {
        "type" : "metric",
        "x" : 0,
        "y" : 6,
        "width" : 12,
        "height" : 6,
        "properties" : {
          "region" : var.region,
          "title" : "DynamoDB Throttles & Conditional Check Failures",
          "metrics" : [
            ["AWS/DynamoDB", "WriteThrottleEvents", "TableName", var.table_name, { stat : "Sum" }],
            ["AWS/DynamoDB", "ConditionalCheckFailedRequests", "TableName", var.table_name, { stat : "Sum" }]
          ],
          "stat" : "Sum",
          "period" : 300
        }
      }
    ]
  })
}

#############################################
# CloudWatch Alarms
#############################################

# 1. Failed Writes (Custom Metric)
resource "aws_cloudwatch_metric_alarm" "failed_writes" {
  alarm_name          = "${var.table_name}-DynamoWriteFailed"
  namespace           = "Custom/MetadataWriter"
  metric_name         = "DynamoWriteFailed"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  alarm_description   = "Writer Lambda is failing to write to DynamoDB."
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    TableName = var.table_name
  }
}

# 2. DynamoDB Native Throttles
resource "aws_cloudwatch_metric_alarm" "dynamodb_throttles" {
  alarm_name          = "${var.table_name}-DynamoDBThrottles"
  namespace           = "AWS/DynamoDB"
  metric_name         = "WriteThrottleEvents"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  alarm_description   = "DynamoDB is throttling write requests. Increase WCU or enable auto-scaling."
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    TableName = var.table_name
  }
}

# 3. Conditional Check Failures (Native DynamoDB metric)
resource "aws_cloudwatch_metric_alarm" "conditional_check_failed" {
  alarm_name          = "${var.table_name}-ConditionalCheckFailed"
  namespace           = "AWS/DynamoDB"
  metric_name         = "ConditionalCheckFailedRequests"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  alarm_description   = "Duplicate keys or constraint check issues on DynamoDB writes."
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    TableName = var.table_name
  }
}

# 4. High Writer Latency (custom metric)
resource "aws_cloudwatch_metric_alarm" "writer_latency" {
  alarm_name          = "${var.table_name}-HighDynamoLatency"
  namespace           = "Custom/MetadataWriter"
  metric_name         = "DynamoLatency"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 1
  threshold           = 200 # ms
  comparison_operator = "GreaterThanThreshold"
  alarm_description   = "DynamoDB write latency is high."
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    TableName = var.table_name
  }
}