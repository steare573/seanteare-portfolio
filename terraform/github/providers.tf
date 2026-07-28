# Authenticates from GITHUB_TOKEN in the environment. Applied from a workstation,
# never from CI — see README.md for why.
provider "github" {
  owner = local.gh_owner
}

locals {
  gh_owner = split("/", var.github_repo)[0]
  gh_repo  = split("/", var.github_repo)[1]
}
