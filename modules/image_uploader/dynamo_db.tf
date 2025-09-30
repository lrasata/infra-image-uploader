# DynamoDB table for file metadata
resource "aws_dynamodb_table" "files_per_user_metadata" {
  name         = "${var.environment}-files-per-user-metadata"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "user_id" # partition key
  range_key    = "file_key"  # sort key

  attribute {
    name = "user_id"
    type = "S"
  }

  attribute {
    name = "file_key"
    type = "S"
  }

  # in terraform you only need to declare partition and sort keys as attributes
  # other attributes can be added dynamically when inserting items

  tags = {
    Environment = var.environment
  }
}