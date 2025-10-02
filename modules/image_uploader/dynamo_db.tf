# DynamoDB table for file metadata
resource "aws_dynamodb_table" "files_metadata" {
  name         = "${var.environment}-files-metadata"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = var.dynamodb_partition_key # partition key
  range_key    = var.dynamodb_sort_key  # sort key

  attribute {
    name = var.dynamodb_partition_key
    type = "S"
  }

  attribute {
    name = var.dynamodb_sort_key
    type = "S"
  }

  # in terraform you only need to declare partition and sort keys as attributes
  # other attributes can be added dynamically when inserting items

  tags = {
    Environment = var.environment
  }
}