resource "aws_sns_topic" "alerts" {
  name = "${var.environment}-${var.app_id}-${var.service_name}-sns-topic"

  tags = {
    Service     = var.service_name
    Environment = var.environment
    App         = var.app_id
  }
}

resource "aws_sns_topic_subscription" "alerts_email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

