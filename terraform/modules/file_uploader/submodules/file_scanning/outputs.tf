output "sns_topic_subscription_arn" {
  description = "ARN of the SNS subscription (if BucketAV enabled)"
  value       = var.use_bucketav ? aws_sns_topic_subscription.lambda[0].arn : null
}

output "sns_topic_arn" {
  description = "ARN of the BucketAV SNS topic (if BucketAV enabled)"
  value       = var.use_bucketav ? data.aws_sns_topic.bucketav_results[0].arn : null
}
