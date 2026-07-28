variable "github_repo" {
  description = "owner/repo these settings apply to."
  type        = string
}

variable "github_branch" {
  description = <<-EOT
    The branch that deploys. Both environments are pinned to it, and it is
    protected against direct pushes.

    Must match `github_branch` in the AWS root — that value goes into the OIDC
    trust policy. The two roots are deliberately independent, so this is the one
    place they have to agree.
  EOT
  type        = string
  default     = "main"
}

variable "github_develop_branch" {
  description = <<-EOT
    Integration branch, created and protected here. Nothing deploys from it —
    the environment branch policies stay pinned to `github_branch` — it exists so
    work can accumulate behind a protected ref before reaching main.
  EOT
  type        = string
  default     = "develop"
}

variable "github_environment" {
  description = <<-EOT
    Actions environment for the Terraform apply job. Carries the required
    reviewer, so infrastructure changes wait for a human.

    Must match `github_environment` in the AWS root, which names it in the OIDC
    trust policy. A mismatch means the apply job cannot assume its role.
  EOT
  type        = string
  default     = "production"
}

variable "github_content_environment" {
  description = <<-EOT
    Actions environment for the site deploy job. No reviewer: publishing is
    idempotent and the bucket is versioned, so a manual approval on every push
    buys nothing.

    Must match `github_content_environment` in the AWS root.
  EOT
  type        = string
  default     = "production-content"
}
