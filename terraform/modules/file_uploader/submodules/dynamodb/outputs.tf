output "files_metadata_table_name" {
  description = "The name of the DynamoDB table"
  value       = aws_dynamodb_table.files_metadata_table.name
}

output "files_metadata_table_arn" {
  description = "The ARN of the DynamoDB table"
  value       = aws_dynamodb_table.files_metadata_table.arn
}