provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.tags
  }
}

# CloudFront is a global service and ACM certificates attached to it MUST live
# in us-east-1, regardless of where anything else runs.
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = local.tags
  }
}

locals {
  tags = {
    Project   = "seanteare-portfolio"
    ManagedBy = "terraform"
    Repo      = var.github_repo
  }

  # Split "owner/repo" so the OIDC trust policy can match GitHub's immutable
  # subject claims, which embed numeric IDs after each segment.
  gh_owner = split("/", var.github_repo)[0]
  gh_repo  = split("/", var.github_repo)[1]

  # Which Actions environment each CI role is allowed to be assumed from.
  # Keyed by role so the two never share a trust document — see github_oidc.tf.
  # The environments themselves are created in terraform/github/.
  github_role_environments = {
    deploy    = var.github_content_environment
    terraform = var.github_environment
  }
}
