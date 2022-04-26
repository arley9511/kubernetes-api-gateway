# Config S3 State Terraform

terraform {
    required_providers {
      aws = {
        source  = "hashicorp/aws"
        version = "3.74.0"
      }
    }

    backend "s3" {
      bucket  = "aws-altais-state"
      key     = "infrastructure/terraform.tfstate"
      region  = "us-east-2"
      profile = "arley_tests"
      shared_credentials_file = "~/.aws/credentials"
  }
}
