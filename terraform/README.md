# Infrastructure

Terraform for `seanteare.com`: S3 origin, CloudFront with Origin Access Control,
ACM certificate, Route 53 zone, and the GitHub OIDC roles the pipeline uses.

**Nothing here has been applied yet.**

> Doing the first deployment? Follow
> [pre-initial-deployment.md](./pre-initial-deployment.md) — it covers the
> bootstrap ordering, why the first run has to be local, and the DNS cutover.

## What it manages

| Resource | State |
|---|---|
| `aws_s3_bucket.site` | **imported** — existing `seanteare.com` bucket |
| `aws_cloudfront_distribution.site` | **imported** — existing `E187XNVZFLAXPG` |
| Bucket policy, public access block, versioning, encryption | new |
| `aws_cloudfront_origin_access_control` | new |
| `aws_cloudfront_function.rewrite_index` | new |
| `aws_acm_certificate` + validation | new |
| `aws_route53_zone` + records | new |
| GitHub OIDC provider + `deploy` / `terraform` roles | new |
| `production` + `production-content` Actions environments | new |
| Branch protection on `main` and `develop` | new |

The bucket and distribution are **imported, not recreated**. A replacement
distribution would get a new `*.cloudfront.net` name and 15–20 minutes of
downtime; importing makes this an in-place update.

## What changes about the current setup

1. **Origin switches from the S3 *website* endpoint to the REST endpoint with
   OAC.** The bucket stops being public and stays behind Block Public Access.
   CloudFront authenticates as a service principal, scoped to this one
   distribution.
2. **A CloudFront Function restores directory-index resolution**, which the
   website endpoint did for free and the REST API does not.
3. **Real TLS.** The distribution currently serves `seanteare.com` using the
   default `*.cloudfront.net` certificate, which fails a name check. It gets a
   validated ACM cert, `redirect-to-https`, and a TLS 1.2 floor (currently
   TLSv1).
4. **DNS moves to Route 53**, which is what makes certificate validation and
   record management automatic.

## Bootstrap

Terraform cannot create the bucket holding its own state. Once, by hand:

```bash
aws s3 mb s3://seanteare-tfstate --region us-east-1
aws s3api put-bucket-versioning --bucket seanteare-tfstate \
  --versioning-configuration Status=Enabled
aws s3api put-public-access-block --bucket seanteare-tfstate \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
```

The first `apply` also has to run from local credentials — the role the pipeline
assumes does not exist until Terraform creates it.

### GitHub credentials

`github_environment.tf` manages the `production` Actions environment, which
needs repo-admin rights. The Actions-issued `GITHUB_TOKEN` **cannot** be granted
them — there is no `permissions:` key for environment administration — so the
provider takes a fine-grained PAT instead.

Create one scoped to this repository with **Administration: read and write**
(environments and branch protection) and **Contents: read and write** (creating
the `develop` branch), then:

```bash
# locally
export GITHUB_TOKEN=github_pat_...

# in CI
gh secret set TF_GITHUB_TOKEN
```

**Set the secret before merging any change that touches `terraform/`.** Without
it the plan fails reading `data.github_user.owner`, which takes the whole
Terraform pipeline down, not just the GitHub resources. The workflow checks for
it up front and fails with that message rather than a provider stack trace, but
it cannot check on the pull request — `terraform validate` never evaluates data
sources, so the failure only appears after merge.

The token expires. When it does, every Terraform run fails on authentication.
The keyless alternative is a GitHub App via `actions/create-github-app-token`,
which is worth the setup if this ever grows past one repository.

## What actually gates production

Four separate mechanisms, each covering a gap the others cannot:

| Gate | Stops |
|---|---|
| Branch protection on `main` | Direct pushes. Changes arrive by pull request, including the maintainer's — `enforce_admins` is on. |
| Deployment branch policy | A job on any other branch deploying through these environments. |
| Required reviewers on `production` | An infrastructure apply running unattended. |
| OIDC trust policy | Any repo, any branch, or any job without an environment assuming the roles at all. |

The reviewer rule is the weakest of the four and should be read honestly: one
maintainer means the reviewer is the person who pushed, self-review is allowed,
and admins can bypass. It stops an apply from happening *unattended*. It is not
an authorization boundary.

The trust policy accepts **only** the environment form of the OIDC subject
claim. A job that omits `environment:` cannot assume either role — which is
deliberate, because the protection rules attach to the environment, so accepting
the ref form would let any job skip all of the above by leaving one line out.

Branch protection requires zero approving reviews. GitHub does not let an author
approve their own pull request, so on a single-maintainer repo any higher number
is unsatisfiable and nothing could merge. The rule doing the work is that a pull
request is required at all.

## Running it

```bash
cd terraform
terraform init
terraform plan     # review carefully: this is where imports show up
terraform apply
```

`plan` and `import` only read AWS. Neither mutates the account — only `apply`
does.

## Order of operations

The domain is currently **suspended for failed WHOIS verification** at Namecheap
and resolves to a parking page, not CloudFront. Steps 2 onward will not work
until that is cleared.

1. **Clear WHOIS verification at Namecheap.** Nothing else matters first.
2. `terraform apply` — creates the zone, cert request, and validation records.
   The `aws_acm_certificate_validation` step **will block** until the domain
   actually resolves through Route 53, so expect this to wait.
3. Copy the `nameservers` output into Namecheap → Domain → Nameservers →
   Custom DNS.
4. Wait for propagation, then confirm: `dig NS seanteare.com`.
5. The blocked apply completes once ACM sees the validation records.
6. Set repo Actions **variables**: `AWS_TERRAFORM_ROLE_ARN`,
   `AWS_DEPLOY_ROLE_ARN`, `AWS_SITE_BUCKET`, `AWS_DISTRIBUTION_ID` — all
   available as Terraform outputs. Set the `TF_GITHUB_TOKEN` **secret** at the
   same time (see [GitHub credentials](#github-credentials)).
7. Update `astro.config.mjs`: remove `base`, set `site = "https://seanteare.com"`.
   **Required** — otherwise every URL keeps the `/seanteare-portfolio/` prefix.
8. Add `src/pages/404.astro` so the CloudFront error mapping has a page.
9. Run `deploy-aws.yml` manually and verify. It now also runs on push to
   `main`; `deploy.yml` (the GitHub Pages workflow) is already gone.

## DNS records carried over

Changing nameservers moves DNS wholesale. Anything not recreated in Route 53
stops resolving at cutover. Read from the live zone beforehand:

- **MX** → `eforward1-5.registrar-servers.com` (Namecheap email forwarding).
  Miss these and mail to the domain fails silently.
- **TXT** → SPF for that forwarder, plus a Google site-verification token.

Both are in `variables.tf`. **Re-check the live zone before cutting over** —
this snapshot was taken while the domain was parked, and a parked zone may not
expose every record.

## Cleanup after cutover

The bucket keeps a website configuration that nothing uses once the origin is
the REST endpoint. Harmless, but removable:

```bash
aws s3api delete-bucket-website --bucket seanteare.com
```

The old 2017 Gatsby content (30 objects) is replaced by the first
`s3 sync --delete`.
