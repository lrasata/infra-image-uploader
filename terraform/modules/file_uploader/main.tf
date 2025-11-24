# Call the S3 buckets submodule
module "s3_buckets" {
  source = "./submodules/s3_buckets"

  environment                   = var.environment
  uploads_bucket_name           = var.uploads_bucket_name
  enable_transfer_acceleration  = var.enable_transfer_acceleration
}

# Call the DynamoDB submodule
module "dynamodb" {
  source = "./submodules/dynamodb"

  environment = var.environment
}

# Call the Secrets Manager submodule
module "secrets" {
  source = "./submodules/secrets"

  secret_store_name    = var.secret_store_name
}

# Call the Lambda Functions submodule
module "lambda_functions" {
  source = "./submodules/lambda_functions"

  environment                                   = var.environment
  region                                        = var.region
  lambda_memory_size_mb                         = var.lambda_memory_size_mb
  lambda_upload_presigned_url_expiration_time_s = var.lambda_upload_presigned_url_expiration_time_s

  # Dependencies from other modules
  uploads_bucket_id              = module.s3_buckets.uploads_bucket_id
  uploads_bucket_arn             = module.s3_buckets.uploads_bucket_arn
  dynamodb_table_name            = module.dynamodb.files_metadata_table_name
  dynamodb_table_arn             = module.dynamodb.files_metadata_table_arn
  dynamodb_partition_key = module.dynamodb.partition_key
  dynamodb_sort_key = module.dynamodb.sort_key
  secret_arn     = module.secrets.secret_arn


  # BucketAV integration
  use_bucketav                   = var.use_bucketav
  auth_secret                    = module.secrets.auth_secret
  enable_transfer_acceleration   = var.enable_transfer_acceleration
}

# Call the API Gateway submodule
module "api_gateway" {
  source = "./submodules/api_gateway"

  environment                = var.environment
  api_file_upload_domain_name = var.api_file_upload_domain_name
  backend_certificate_arn = var.backend_certificate_arn

  # Lambda integration
  get_presigned_url_lambda_function_name  = module.lambda_functions.get_presigned_url_function_name
  get_presigned_url_lambda_arn   = module.lambda_functions.get_presigned_url_function_arn

}

# Call the WAF submodule
module "waf" {
  source = "./submodules/waf"

  environment = var.environment
  api_gateway_stage_arn = module.api_gateway.api_gateway_stage_arn
}

# Call the Route53 submodule (if DNS is managed)
module "route53" {
  source = "./submodules/route53"

  api_file_upload_domain_name      = var.api_file_upload_domain_name
  api_gateway_regional_domain_name = module.api_gateway.api_gateway_domain_name_regional_domain_name
  api_gateway_regional_zone_id     = module.api_gateway.api_gateway_domain_name_regional_zone_id
  route53_zone_name                = var.route53_zone_name
}

# Optional: Antivirus submodule (conditional based on use_bucketav)
module "antivirus" {
  count  = var.use_bucketav ? 1 : 0
  source = "./submodules/antivirus"

  environment                    = var.environment
  bucketav_sns_findings_topic_name = var.bucketav_sns_findings_topic_name
  uploads_bucket_id              = module.s3_buckets.uploads_bucket_id
}