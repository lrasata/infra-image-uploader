variable "bucket_name" {
  description = "Name of the S3 bucket."
  type        = string
}

variable "bucket_id" {
  description = "ID of the S3 bucket."
  type        = string
}

variable "sns_topic_arn" {
  description = "SNS topic for alarms."
  type        = string
}

variable "region" {
  type = string
}