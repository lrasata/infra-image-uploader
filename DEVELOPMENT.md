# Instructions for Setting Up Infrastructure with Terraform

## Prerequisites

- **Terraform** >= 1.3 installed: https://www.terraform.io/downloads.html
- Access to **AWS configured**
- **Secret values** are configured saved in Secrets Manager:
  - secrets : `${var.environment}/image-upload/secrets`
    - CUSTOM_AUTH_SECRET : Secret value of header X-Custom-Auth which allows client to request presigned url to upload images.
- Build `sharp` for Lambda function
  - Refer to [HOW_TO](HOW_TO.md) section
- Optional: **BucketAV** stack to be successfully deployed.
  - BucketAV is the antivirus used and tested in this project. You can disable it by providing `var.use_bucketav = false`
  - If you decide to use BucketAV (highly recommended), after purchasing it on AWS Marketplace then follow the [steps to deploy the bucketav stack](https://bucketav.com/help/setup-guide/amazon-s3-step-1.html)
    - once bucketav stack is successfully created, follow the steps below

## Getting Started

**1. Clone the repository:**

```bash
git clone https://github.com/lrasata/infra-image-uploader.git
cd infra-image-uploader
```

**2. Initialize Terraform:**

````bash
terraform init
````

**3. Format configuration:**

````bash
terraform fmt
````

**4. Validate configuration:**

````bash
terraform validate
````

**5. Choose your environment and plan/apply:**

This project uses .tfvars files to handle multiple environments (e.g., dev, staging, prod).

**Example .tfvars files:**

````text
# staging.tfvars
region      = "eu-central-1"
environment = "staging"

api_image_upload_domain_name = "staging-api-image-upload.epic-trip-planner.com"
backend_certificate_arn      =

uploads_bucket_name          = "trip-planner-app-uploads-bucket"
enable_transfer_acceleration = true


lambda_upload_presigned_url_expiration_time_s = 300 # 5min

use_bucketav                     = true
bucketav_sns_findings_topic_name = "bucketav-FindingsTopic-id"
````


Plan and apply for a specific environment:

````text
terraform plan -var-file="staging.tfvars"
terraform apply -var-file="staging.tfvars"
````

## Notes

- Always review the output of terraform plan before applying changes.
- Keep .terraform.lock.hcl committed for consistent provider versions.

## Destroying Infrastructure

To tear down all resources managed by this project:

````bash
terraform destroy -var-file="staging.tfvars"
````

Replace `staging.tfvars` with the appropriate tfvars environment file.