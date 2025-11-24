variable "environment" {
  description = "The environment for the deployment (e.g., dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "The AWS region to deploy resources"
  type        = string
}

variable "lambda_upload_presigned_url_expiration_time_s" {
  description = "Expiration time in seconds for the pre-signed URL"
  type        = number
}

variable "lambda_memory_size_mb" {
  description = "Memory size in MB for process uploaded file Lambda"
  type        = number
}

variable "enable_transfer_acceleration" {
  description = "Enable S3 Transfer Acceleration"
  type        = bool
}

variable "use_bucketav" {
  description = "Use BucketAV for malware scanning"
  type        = bool
}

variable "uploads_bucket_id" {
  description = "ID of the uploads S3 bucket"
  type        = string
}

variable "uploads_bucket_arn" {
  description = "ARN of the uploads S3 bucket"
  type        = string
}

variable "auth_secret" {
  description = "API Gateway authentication secret"
  type        = string
  sensitive   = true
}

variable "secret_arn" {
  description = "ARN of the Secrets Manager secret"
  type        = string
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  type        = string
}

variable "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table"
  type        = string
}

variable "dynamodb_partition_key" {
  description = "Partition key name for the DynamoDB table"
  type        = string
}

variable "dynamodb_sort_key" {
  description = "Sort key name for the DynamoDB table"
  type        = string
}

variable "lambda_process_uploaded_file_dir" {
  description = "Path to built Lambda directory, including node_modules"
  type        = string
}
