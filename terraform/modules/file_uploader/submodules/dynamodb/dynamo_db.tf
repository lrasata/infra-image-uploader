locals {
  partition_key = "id"
  sort_key      = "file_key"
}
resource "aws_dynamodb_table" "files_metadata_table" {
  name         = "${var.environment}-files-metadata"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = local.partition_key
  range_key    = local.sort_key

  attribute {
    name = local.partition_key
    type = "S"
  }

  attribute {
    name = local.sort_key
    type = "S"
  }

  tags = {
    Environment = var.environment
  }

  deletion_protection_enabled = var.environment == "prod" ? true : false

  point_in_time_recovery {
    enabled = true
  }
}
