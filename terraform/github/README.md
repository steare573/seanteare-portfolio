# Repository settings

Terraform for the GitHub side of the pipeline: the two Actions environments and
their protection rules, and branch protection on `main` and `develop`.

Separate root, separate state, **applied by hand**. That is the whole point of
this directory, so it is worth being explicit about why.

## Why CI does not apply this

The AWS root is applied by `.github/workflows/terraform.yml`, which assumes a
role that can reshape CloudFront, IAM, and DNS. Terraform providers are
arbitrary code fetched from a registry, so anything that compromises that job
already owns the infrastructure.

Handing that same job a repo-admin GitHub credential would make it strictly
worse: an attacker could switch off the branch protection and the required
reviewer — the rules that gate the pipeline itself — and then keep going
quietly. Keeping the credential out of CI means a compromise cannot rewrite its
own guardrails.

The tradeoff is real and worth naming: settings changes are not applied on
merge. Someone has to run `apply`. These change perhaps twice a year, and CI
still validates this root on every pull request, so the risk is drift rather
than breakage.

## Applying

```bash
cd terraform/github
export GITHUB_TOKEN="$(gh auth token)"
terraform init
terraform plan
terraform apply
```

`gh auth token` reuses the CLI session already on the machine, which is the
reason no personal access token exists for this repo and no GitHub credential is
stored in Actions secrets. If you ever need a PAT instead — CI, another machine,
a different account — it needs **Administration: read and write** (environments,
protection rules, branch protection) and **Contents: read and write** (creating
`develop`).

## What it manages

| Resource | Effect |
|---|---|
| `github_repository_environment.production` | Required reviewer. Infrastructure applies wait for a human. |
| `github_repository_environment.content` | No reviewer. Content deploys run unattended. |
| `github_repository_environment_deployment_policy.*` | Both environments pinned to `main`. |
| `github_branch.develop` | Creates the integration branch. |
| `github_branch_protection.protected["main"]` / `["develop"]` | Pull request required, no force-push, no delete, applies to admins. |

## What actually gates production

Four mechanisms, each covering a gap the others cannot:

| Gate | Stops | Lives in |
|---|---|---|
| Branch protection | Direct pushes to `main`. | here |
| Deployment branch policy | A job on another branch deploying. | here |
| Required reviewers | An infrastructure apply running unattended. | here |
| OIDC trust policy | Another repo, branch, or an environment-less job assuming the roles. | `../github_oidc.tf` |

Read the reviewer rule honestly: one maintainer means the reviewer is the person
who pushed, self-review is permitted, and admins can bypass. It stops an apply
happening *unattended*. It is not an authorization boundary.

Branch protection requires **zero** approving reviews. GitHub will not let an
author approve their own pull request, so any higher number is unsatisfiable on
a single-maintainer repo and nothing could ever merge. The rule doing the work
is that a pull request is required at all. Raise the count when there is a
second maintainer.

## Shared values

Four variables must agree with the AWS root, which names the environments in its
OIDC trust policy:

- `github_repo`
- `github_branch`
- `github_environment`
- `github_content_environment`

Duplicated deliberately. Wiring them through `terraform_remote_state` would
couple the two roots and reintroduce the dependency this split exists to remove.
A mismatch shows up immediately: the affected job fails to assume its role.
