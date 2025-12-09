resource "aws_cloudwatch_dashboard" "thumbnail_generation_lambda_dashboard" {
  dashboard_name = "${var.environment}-thumbnail-generation-lambda-dashboard"

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
            ["Custom/ThumbnailGenerator", "ThumbnailRequested", { stat : "Sum" }],
            ["Custom/ThumbnailGenerator", "ThumbnailGenerated", { stat : "Sum" }],
            ["Custom/ThumbnailGenerator", "ThumbnailFailed", { stat : "Sum" }]
          ]
          period = 300
          stat   = "Sum"
          title  = "Thumbnail Requests & Success/Failure"
          region = var.region
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
            ["Custom/ThumbnailGenerator", "ThumbnailDuration", { stat : "Average" }],
            ["Custom/ThumbnailGenerator", "ThumbnailLambdaErrors", { stat : "Sum" }]
          ]
          period = 60
          stat   = "Average"
          title  = "Performance & Errors"
          region = var.region
        }
      }
    ]
  })
}
