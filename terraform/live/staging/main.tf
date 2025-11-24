module "file_uploader" {
  source = "../../modules/file_uploader"

  lambda_process_uploaded_file_dir = "../../../terraform/modules/file_uploader/submodules/lambda_functions/src/lambdas/process_uploaded_file"

  region                                        = var.region
  environment                                   = var.environment
  secret_store_name                             = var.secret_store_name
  api_file_upload_domain_name                   = var.api_file_upload_domain_name
  backend_certificate_arn                       = var.backend_certificate_arn
  uploads_bucket_name                           = var.uploads_bucket_name
  enable_transfer_acceleration                  = var.enable_transfer_acceleration
  lambda_upload_presigned_url_expiration_time_s = var.lambda_upload_presigned_url_expiration_time_s
  use_bucket_av                                 = var.use_bucketav
  bucket_av_sns_findings_topic_name             = var.bucketav_sns_findings_topic_name
  lambda_memory_size_mb                         = var.lambda_memory_size_mb
  route53_zone_name                             = var.route53_zone_name
}