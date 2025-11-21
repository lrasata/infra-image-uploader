# Instructions for Setting Up Infrastructure with Terraform

## Prerequisites

- **Terraform** >= 1.3 installed: https://www.terraform.io/downloads.html
- Access to **AWS configured**
- **Secret values** are configured saved in Secrets Manager:
  - secrets : `${var.environment}/file-upload/secrets`
    - API_GW_AUTH_SECRET : Secret value of header `x-api-gateway-img-upload-auth` which allows client to request presigned url to upload files.
- Build `sharp` and `aws-sdk` for Lambda function `process-uploaded-file-lambda`
  - Refer to [HOW_TO](HOW_TO.md) section
- **Important:**
  - Decide what should be the max size of file upload. Depending on this value, you might adjust the **memory size** allocated for Lambda processing file. It can be configured from 128 MB up to 10,240 MB. Default value in this terraform project is **512 MB**
- Optional: **BucketAV** stack to be successfully deployed.
  - BucketAV is the antivirus used and tested in this project. You can disable it by providing `var.use_bucketav = false`
  - If you decide to use BucketAV (highly recommended), after purchasing it on AWS Marketplace then follow the [steps to deploy the bucketav stack](https://bucketav.com/help/setup-guide/amazon-s3-step-1.html)
    - once bucketav stack is successfully created, follow the steps below

## Getting Started

**1. Clone the repository:**

```bash
git clone https://github.com/lrasata/infra-file-uploader.git
cd infra-file-uploader
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

api_file_upload_domain_name = "staging-api-file-upload.epic-trip-planner.com"
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

## Usage 

Use the specified API Gateway endpoint to request a presigned URL to upload a file.

````text
# Endpoint that returns the presigned URL
presign_endpoint =  "https://${api_file_upload_domain_name}/upload-url"
````

Specify the secret value of the header `x-api-gateway-img-upload-auth`

````text
# Custom auth header required by your Lambda
headers = {
    "x-api-gateway-img-upload-auth": "secret"
}
````

Provide the following query parameters:

````text
params = {
  [partition_key]: "id",
  [sort_key]: "file_key",
  "ext": "png",
  "resource": "trips"
}
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