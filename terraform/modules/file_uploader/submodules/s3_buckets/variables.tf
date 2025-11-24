
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "uploads_bucket_name" {
  description = "Base name for the uploads S3 bucket"
  type        = string
}

variable "enable_transfer_acceleration" {
  description = "Enable S3 Transfer Acceleration for faster uploads"
  type        = bool
  default     = false
}


variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project = "file-uploader"
  }
}