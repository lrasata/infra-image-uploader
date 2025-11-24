variable "environment" {
  description = "The environment for the deployment (e.g., dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "eu-central-1"
}

variable "api_file_upload_domain_name" {
  description = "The domain name for the API Gateway"
  type        = string
}

variable "backend_certificate_arn" {
  description = "The ARN of the ACM certificate for the domain"
  type        = string
}

variable "get_presigned_url_lambda_function_name" {
  description = "Name of the get presigned URL Lambda function"
  type        = string
}

variable "get_presigned_url_lambda_arn" {
  description = "ARN of the get presigned URL Lambda function"
  type        = string
}