output "api_gateway_invoke_url" {
  description = "Public URL for invoking the API Gateway"
  value       = "https://${var.api_image_upload_domain_name}/upload-url"
}