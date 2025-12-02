terraform {
  backend "s3" {
    bucket         = "file-uploader-terraform-state-387836084035"
    key            = "ephemeral/terraform.tfstate"
    region         = "eu-central-1"
    encrypt        = true
    dynamodb_table = "ephemeral-file-uploader-terraform-locks"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.18"
    }
  }

  required_version = ">= 1.6.0, < 2.0.0"
}

provider "aws" {
  region = var.region
}