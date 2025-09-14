# Image uploader infrastructure - managed with Terraform on AWS 🚧

## Overview

This project provides a **Terraform module** that allows clients to upload image files securely to AWS.
It supports **optional malware scanning via BucketAV**, thumbnail generation, and user metadata storage in DynamoDB.

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

## Key attributes

### Security

- Optional **BucketAV integration** to scan for malware before files are processed.
  - BucketAV scan is triggered after each upload and by default it deletes any infected file. (Behaviour can be changed in BucketAV settings)
- All files are stored in **S3 with default encryption SSE-S3**  at rest.
- **Public access blocked** on the bucket to prevent unauthorized access.

### Reliability

- AWS Lambda ensures **automatic scaling and high availability**.
- S3 provides effective unlimited storage.
  - Maximum object size: 5 TB per object.
  - Maximum number of objects per bucket: unlimited.
- SNS delivery ensures Lambda processing occurs only after BucketAV scan completes. **Lambda only process files which are tagged "clean" by BucketAV.**

### Scalability

- Lambda scales automatically with incoming SNS messages or S3 events.
- Optional **S3 Transfer Acceleration** provides global upload speed improvements.

### Maintainability

- **Fully modular Terraform code**, easy to reuse across projects and environments.
- **Environment-specific variables** allow dev/staging/prod separation.
- Lambda functions are decoupled from S3 and SNS triggers, making updates safe and predictable.

## 🔍 Infrastructure choice explanation

- [ ] Why BucketAV (purchased option) vs ClamAV custom code
- [ ] Why DynamoDB
- [ ] ... 