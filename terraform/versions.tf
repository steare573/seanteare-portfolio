terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Remote state. The bucket must exist BEFORE the first `terraform init` —
  # Terraform cannot create the bucket that holds its own state. See README.
  #
  # use_lockfile replaces the old DynamoDB lock table (Terraform >= 1.10).
  backend "s3" {
    bucket       = "seanteare-tfstate"
    key          = "seanteare-portfolio/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
