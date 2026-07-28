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

# Authenticates from GITHUB_TOKEN in the environment. Managing an environment's
# protection rules needs repo-admin rights, which the Actions-issued GITHUB_TOKEN
# cannot be granted — `permissions:` has no key for it. CI therefore supplies a
# fine-grained PAT; see the README.
provider "github" {
  owner = local.gh_owner
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
  github_role_environments = {
    deploy    = var.github_content_environment
    terraform = var.github_environment
  }
}

data "aws_caller_identity" "current" {}
