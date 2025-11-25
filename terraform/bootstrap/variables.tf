variable "s3_bucket_name_prefix" {
  type = string
}

variable "environment" {
  description = "The environment for the deployment (e.g., dev, staging, prod)"
  type        = string
}

variable "app_id" {
  type = string
}