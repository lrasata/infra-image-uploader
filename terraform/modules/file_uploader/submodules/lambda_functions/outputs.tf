output "get_presigned_url_function_name" {
  description = "Name of the get presigned URL Lambda function"
  value       = aws_lambda_function.get_presigned_url.function_name
}

output "get_presigned_url_function_arn" {
  description = "ARN of the get presigned URL Lambda function"
  value       = aws_lambda_function.get_presigned_url.arn
}

output "process_uploaded_file_function_name" {
  description = "Name of the process uploaded file Lambda function"
  value       = aws_lambda_function.process_uploaded_file.function_name
}

output "process_uploaded_file_function_arn" {
  description = "ARN of the process uploaded file Lambda function"
  value       = aws_lambda_function.process_uploaded_file.arn
}

output "upload_folder" {
  description = "Folder name in s3 bucket where files are uploaded"
  value       = local.upload_folder
}