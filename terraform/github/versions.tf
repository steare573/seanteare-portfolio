terraform {
  required_version = ">= 1.10.0"

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }

  # Separate state from the AWS root. Same bucket, different key — the two are
  # applied by different people at different times and should not be able to
  # break each other.
  backend "s3" {
    bucket       = "seanteare-tfstate"
    key          = "seanteare-portfolio/github.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
