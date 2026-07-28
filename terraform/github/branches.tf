/**
 * Branch protection.
 *
 * The environment rules in environments.tf answer "which branch may
 * deploy". They say nothing about who may put commits on that branch. Until
 * these rules exist, `main` accepts a direct push from anyone with write
 * access, and that push publishes to production.
 *
 * Both branches are protected identically: changes arrive through a pull
 * request, force-push and delete are refused, and the rules apply to admins
 * too. `enforce_admins` is the difference between a protected branch and a
 * suggestion — without it the one person most likely to push directly is
 * exempt.
 */

# `develop` does not exist yet. Cut from main so the branch protection below has
# something to attach to; Terraform will not touch its contents afterwards.
resource "github_branch" "develop" {
  repository    = local.gh_repo
  branch        = var.github_develop_branch
  source_branch = var.github_branch
}

locals {
  protected_branches = toset([
    var.github_branch,
    github_branch.develop.branch,
  ])
}

resource "github_branch_protection" "protected" {
  for_each = local.protected_branches

  repository_id = local.gh_repo
  pattern       = each.value

  # This is what closes direct pushes. Zero approvals is not an oversight:
  # GitHub does not let an author approve their own pull request, so on a
  # single-maintainer repo any non-zero count is an unsatisfiable condition and
  # nothing could ever merge. The rule doing the work here is "a pull request is
  # required at all", which holds at zero.
  #
  # Raise this the moment a second maintainer exists.
  required_pull_request_reviews {
    required_approving_review_count = 0
  }

  # Applies the rules to admins as well. Without it, the repo owner keeps a
  # direct-push path and the protection is decorative.
  enforce_admins = true

  allows_force_pushes = false
  allows_deletions    = false

  # Deliberately not set:
  #
  #   required_status_checks — terraform.yml only runs its validate job on pull
  #   requests that touch terraform/, so requiring that context would block
  #   every unrelated pull request on a check that never starts.
  #
  #   require_signed_commits — no signing set up yet. Turning it on here would
  #   lock the maintainer out of their own repository.
}
