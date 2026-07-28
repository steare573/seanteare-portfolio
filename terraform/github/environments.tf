/**
 * Protection rules for the Actions environments the pipeline deploys through.
 *
 * Two environments, because the two jobs carry very different risk:
 *
 *   production          terraform.yml -> plan_apply. Reshapes CloudFront, IAM,
 *                       and DNS. Waits for a human.
 *   production-content  deploy-aws.yml -> deploy. Syncs the built site and
 *                       invalidates the cache. Runs unattended.
 *
 * Both are pinned to main. The reviewer is what differs, and it differs on
 * purpose: a content deploy is idempotent against a versioned bucket, so a
 * manual approval on every push would be friction without a corresponding gain.
 *
 * The split is also load-bearing for IAM. Each environment maps to exactly one
 * role in ../github_oidc.tf, so an unreviewed content deploy cannot assume the
 * role that can rewrite infrastructure.
 */

# Numeric user ID for the reviewer list. The API takes IDs, not logins.
data "github_user" "owner" {
  username = local.gh_owner
}

# ---------------------------------------------------------------------------
# Infrastructure — reviewed.
# ---------------------------------------------------------------------------

resource "github_repository_environment" "production" {
  repository  = local.gh_repo
  environment = var.github_environment

  # Applies pause here until a human approves the run.
  #
  # Worth being honest about what this is: with one maintainer, the reviewer is
  # the same person who pushed, self-review is permitted, and admins can bypass.
  # It stops an apply reaching production *unattended*. It is not an
  # authorization boundary, and nothing here pretends otherwise.
  reviewers {
    users = [data.github_user.owner.id]
  }

  # Left false deliberately. This repo has one maintainer, who is also the only
  # reviewer — blocking self-review would make every apply unapprovable.
  prevent_self_review = false

  # Explicit rather than inherited. This is GitHub's default, so it changes
  # nothing today, but it is a security-relevant setting and should show up in a
  # diff if it ever moves.
  can_admins_bypass = true

  deployment_branch_policy {
    protected_branches     = false
    custom_branch_policies = true
  }
}

resource "github_repository_environment_deployment_policy" "production_main_only" {
  repository     = local.gh_repo
  environment    = github_repository_environment.production.environment
  branch_pattern = var.github_branch
}

# ---------------------------------------------------------------------------
# Content — unattended, but still main-only.
# ---------------------------------------------------------------------------

resource "github_repository_environment" "content" {
  repository  = local.gh_repo
  environment = var.github_content_environment

  # No `reviewers` block. That is the point of the split — see the header.

  can_admins_bypass = true

  deployment_branch_policy {
    protected_branches     = false
    custom_branch_policies = true
  }
}

resource "github_repository_environment_deployment_policy" "content_main_only" {
  repository     = local.gh_repo
  environment    = github_repository_environment.content.environment
  branch_pattern = var.github_branch
}

# ---------------------------------------------------------------------------
# Why the branch policies exist at all.
#
# The IAM trust policy cannot carry this constraint. Declaring `environment:`
# makes GitHub swap the OIDC subject claim from the ref form to the environment
# form:
#   no environment  -> repo:...:ref:refs/heads/main
#   environment set -> repo:...:environment:production
# The environment form names no branch, so AWS would accept the claim no matter
# which branch the job ran on. These policies put "main only" back.
#
# `protected_branches` is not used: it means "any branch carrying protection
# rules", which is both looser and different. An explicit pattern says what is
# meant, and it fails safe — `protected_branches = true` against a repo with no
# protected branches matches nothing and blocks every deploy.
# ---------------------------------------------------------------------------
