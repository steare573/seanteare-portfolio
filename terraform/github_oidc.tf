/**
 * GitHub Actions authentication via OIDC — no long-lived access keys in repo
 * secrets. Actions requests a short-lived token from GitHub, AWS validates it
 * against this provider, and hands back temporary credentials.
 */

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  # AWS stopped validating this thumbprint for GitHub's provider in 2023 (it
  # trusts the CA chain directly), but the API still requires the field.
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# One trust document per role, each naming exactly one environment.
#
# A single shared document would undo the gate: the content-deploy environment
# has no required reviewer, so any subject good enough to deploy content would
# also be good enough to assume the terraform role, which can reshape the CDN,
# IAM, and DNS. Each role trusts only the environment its own job runs in.
data "aws_iam_policy_document" "github_assume_role" {
  for_each = local.github_role_environments

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Pinning `sub` is what stops a fork or an arbitrary branch from assuming
    # the role. Without it, any workflow in any repo that can reach this account
    # could deploy.
    #
    # Two independent things vary in this claim, and both were verified against
    # a real token rather than assumed:
    #
    # 1. Environment. When a job declares `environment:`, GitHub replaces the
    #    ref filter with an environment filter:
    #      no environment  -> ...:ref:refs/heads/main
    #      environment set -> ...:environment:production
    #
    #    ONLY the environment form is accepted here. Accepting the ref form
    #    alongside it would leave the protection rules trivially bypassable: the
    #    rules attach to the environment, so a job on main that simply omits
    #    `environment:` would emit the ref form, match, and assume the role with
    #    no reviewer and no branch policy in the way. Both jobs declare an
    #    environment, so the ref form has no legitimate use — only that one.
    #
    #    A new job that needs AWS must therefore declare an environment. That is
    #    the intended constraint, not an oversight.
    #
    # 2. Immutable IDs. GitHub now issues subject claims carrying numeric owner
    #    and repository IDs, so the identity survives a rename:
    #      classic   -> repo:steare573/seanteare-portfolio:...
    #      immutable -> repo:steare573@898480/seanteare-portfolio@1314133354:...
    #    The observed token uses the immutable form.
    #
    # StringLike is used only to wildcard the numeric IDs. Owner name, repo
    # name, and the environment remain exact, so this is no looser than an exact
    # match on identity — it just tolerates both claim formats.
    #
    # The environment form carries no branch, so the branch restriction has to
    # live in the environment's deployment branch policy — see
    # github/environments.tf.
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.github_repo}:environment:${each.value}",
        "repo:${local.gh_owner}@*/${local.gh_repo}@*:environment:${each.value}",
      ]
    }
  }
}

# ---------------------------------------------------------------------------
# Content deploy role — sync the build and invalidate the cache. Nothing else.
# ---------------------------------------------------------------------------

resource "aws_iam_role" "deploy" {
  name               = "seanteare-site-deploy"
  description        = "GitHub Actions: sync built site to S3 and invalidate CloudFront"
  assume_role_policy = data.aws_iam_policy_document.github_assume_role["deploy"].json
}

data "aws_iam_policy_document" "deploy" {
  statement {
    sid    = "SyncSiteObjects"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:GetObject",
    ]
    resources = ["${aws_s3_bucket.site.arn}/*"]
  }

  statement {
    sid       = "ListBucketForSyncDiff"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.site.arn]
  }

  statement {
    sid    = "InvalidateCache"
    effect = "Allow"
    actions = [
      "cloudfront:CreateInvalidation",
      "cloudfront:GetInvalidation",
    ]
    resources = [aws_cloudfront_distribution.site.arn]
  }
}

resource "aws_iam_role_policy" "deploy" {
  name   = "site-deploy"
  role   = aws_iam_role.deploy.id
  policy = data.aws_iam_policy_document.deploy.json
}

# ---------------------------------------------------------------------------
# Terraform role — runs plan/apply in CI.
#
# Scoped to the services this stack touches rather than AdministratorAccess.
# It is still broad: it can reshape the CDN and IAM roles for this project, so
# the environment pin above is doing real work — that environment is the one
# carrying the required-reviewer rule.
# ---------------------------------------------------------------------------

resource "aws_iam_role" "terraform" {
  name               = "seanteare-terraform"
  description        = "GitHub Actions: terraform plan and apply for the site stack"
  assume_role_policy = data.aws_iam_policy_document.github_assume_role["terraform"].json
}

data "aws_iam_policy_document" "terraform" {
  statement {
    sid    = "ManageSiteStack"
    effect = "Allow"
    actions = [
      "s3:*",
      "cloudfront:*",
      "acm:*",
      "route53:*",
      "iam:GetRole",
      "iam:GetRolePolicy",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies",
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:UpdateRole",
      "iam:PutRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:TagRole",
      "iam:ListInstanceProfilesForRole",
      "iam:GetOpenIDConnectProvider",
      "iam:CreateOpenIDConnectProvider",
      "iam:DeleteOpenIDConnectProvider",
      "iam:UpdateOpenIDConnectProviderThumbprint",
      "iam:TagOpenIDConnectProvider",
      "sts:GetCallerIdentity",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "terraform" {
  name   = "terraform-site-stack"
  role   = aws_iam_role.terraform.id
  policy = data.aws_iam_policy_document.terraform.json
}
