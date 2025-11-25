# Specify below the corresponding values related to this deployment
terraform {
  backend "s3" {
    bucket         = "file-uploader-terraform-state-387836084035"
    key            = "staging/terraform.tfstate"
    region         = "eu-central-1"
    encrypt        = true
    dynamodb_table = "staging-file-uploader-terraform-locks"
  }
}
