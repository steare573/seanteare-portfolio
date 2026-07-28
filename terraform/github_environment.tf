/**
 * Protection rules for the `production` Actions environment.
 *
 * Both CI jobs run against this environment — `terraform.yml` applies
 * infrastructure and `deploy-aws.yml` writes to S3 and invalidates CloudFront.
 * Without rules here, a push reaches live infrastructure unattended.
 */

# Numeric user ID for the reviewer list. The API takes IDs, not logins.
data "github_user" "owner" {
  username = local.gh_owner
}

resource "github_repository_environment" "production" {
  repository  = local.gh_repo
  environment = var.github_environment

  # Applies and deploys pause here until a human approves the run.
  reviewers {
    users = [data.github_user.owner.id]
  }

  # Left false deliberately. This repo has one maintainer, who is also the only
  # reviewer — blocking self-review would make every deploy unapprovable.
  prevent_self_review = false

  # The branch gate that the IAM trust policy can no longer provide.
  #
  # When a job declares `environment:`, GitHub swaps the OIDC subject claim from
  # the ref form to the environment form:
  #   no environment  -> repo:...:ref:refs/heads/main
  #   environment set -> repo:...:environment:production
  # The environment form carries no branch, so AWS sees an acceptable claim no
  # matter which branch the job ran on. Restricting deployment branches here is
  # what puts the "main only" rule back. See the comments in github_oidc.tf.
  #
  # `protected_branches` would mean "any branch with protection rules", which is
  # a different and looser statement than "main". Use an explicit pattern.
  deployment_branch_policy {
    protected_branches     = false
    custom_branch_policies = true
  }
}

resource "github_repository_environment_deployment_policy" "main_only" {
  repository     = local.gh_repo
  environment    = github_repository_environment.production.environment
  branch_pattern = var.github_branch
}
