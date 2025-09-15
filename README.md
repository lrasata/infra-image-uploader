# Image uploader infrastructure - managed with Terraform on AWS

## Overview

This project provides a **Terraform module** that allows clients to upload images securely to AWS.
It supports **optional malware scanning via BucketAV**, thumbnail generation, and user metadata storage in DynamoDB.
This infrastrcture is a **100% serveless**.

**Flow overview:**

1. Client requests a presigned URL from an API exposed via **API Gateway**.
2. Client **uploads the file directly to S3** using the presigned URL.
3. If **BucketAV** is enabled:
   - The upload triggers a scan.
   - BucketAV publishes results to an SNS topic.
   - Lambda subscribed to the topic generates thumbnails and saves metadata in DynamoDB.
4. If BucketAV is **disabled**:
   - Lambda is triggered directly by the **S3 object creation notification**.
5. Thumbnail is stored in a dedicated S3 folder `thumbnails/`, and metadata (file key, thumbnail key, user ID, etc.) is recorded in **DynamoDB**.


<img src="docs/upload-image-infra.png" alt="image-uploader-infrastructure">

## Usage

Use in a terraform project by importing the module:

```text
module "image_uploader" {
  source = "git::https://github.com/lrasata/infra-image-uploader.git?ref=v1.0.0"

  region                                        = var.region
  environment                                   = var.environment
  api_image_upload_domain_name                  = var.api_image_upload_domain_name
  backend_certificate_arn                       = var.backend_certificate_arn
  uploads_bucket_name                           = var.uploads_bucket_name
  enable_transfer_acceleration                  = var.enable_transfer_acceleration
  lambda_upload_presigned_url_expiration_time_s = var.lambda_upload_presigned_url_expiration_time_s
  use_bucketav                                  = var.use_bucketav
  bucketav_sns_findings_topic_name              = var.bucketav_sns_findings_topic_name
}
```
>
> **Prerequisites** to successfully deploy this infrastructure, are described in the Prerequisites section of [DEVELOPMENT.md](DEVELOPMENT.md)
>

### Access object in S3 uploads private bucket

This section only describes a suggestion/recommendation but how you decide to access S3 uploads bucket depends on your project requirements.

One way to securely serves files from a private S3 bucket is through **CloudFront distribution with Origin Access Control (OAC) + bucket policy**. This way, the bucket stays **private**, and only **CloudFront** can access it. End-users get **signed URLs** or **signed cookies**.

The following outputs are provided by the module to allow a set up with cloudfront.

````text
output "uploads_bucket_id" {
  description = "The S3 uploads bucket ID (name)"
  value       = aws_s3_bucket.s3_bucket_uploads.id
}

output "uploads_bucket_arn" {
  description = "The ARN of the S3 uploads bucket"
  value       = aws_s3_bucket.s3_bucket_uploads.arn
}

output "uploads_bucket_regional_domain_name" {
  description = "The regional domain name of the S3 bucket (for CloudFront origin)"
  value       = aws_s3_bucket.s3_bucket_uploads.bucket_regional_domain_name
}

Usage : 
origin_bucket_arn = module.image_uploader.uploads_bucket_arn
````

> FYI: Currently testing the integration of `image-uploader` within the infrascture of a full-stack web application: [trip-planner-web-app](https://github.com/lrasata/infra-trip-planner-webapp)

## Key attributes

### Security

- Optional **BucketAV integration** to scan for malware before files are processed.
  - BucketAV scan is triggered after each upload and by default it deletes any infected file. (This behaviour can be changed in BucketAV settings)
- All files are stored in **S3 with default encryption SSE-S3**  at rest.
- **Public access blocked** on the S3 uploads bucket to prevent unauthorized access.
- **WAF** is attached to API Gateway to filter out bad traffic (bots, throttling, sql injection, etc.). It also blocks any unauthorised requests which do not contain required auth header.

### Reliability

- Lambda ensures **automatic scaling and high availability**.
- S3 provides effective unlimited storage.
  - Maximum object size: 5 TB per object.
  - Maximum number of objects per bucket: unlimited.
- SNS delivery ensures Lambda processing occurs only after BucketAV scan completes. **Lambda only process files which are tagged "clean" by BucketAV.**

### Scalability

- Lambda scales automatically with incoming SNS messages or S3 events.
- Optional **S3 Transfer Acceleration** provides global upload speed improvements.

### Maintainability

- **This Terraform project is built as a module**, it makes it easy to reuse across projects and environments.
- **Environment-specific variables** allow dev/staging/prod separation.
- Lambda functions are decoupled from S3 and SNS triggers, making updates safe and predictable.
