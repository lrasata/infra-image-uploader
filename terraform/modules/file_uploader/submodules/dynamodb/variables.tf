variable "environment" {
  description = "Environment name (dev, staging, prod, ...)"
  type        = string
}

variable "app_id" {
  description = "Application identifier for tagging resources"
  type        = string
  default     = ""
}
