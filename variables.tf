variable "region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "eu-central-1"
}

variable "bucket_name" {
  description = "The name of the S3 bucket for the React app"
  type        = string
  default     = "trip-planner-app-bucket"
}

variable "environment" {
  description = "The environment for the deployment (e.g., dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "backend_certificate_arn" {
  description = "The ARN of the ACM certificate for the ALB HTTPS listener and API Gateway"
  type        = string
}

variable "api_image_upload_domain_name" {
  description = "The domain name for the API to get pre-signed image upload URLs"
  type        = string
  default     = "api-image-upload.epic-trip-planner.com"
}