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

Repository settings — Actions environments, protection rules, branch protection
— live in a **separate root** at [`github/`](./github/README.md) with its own
state, applied by hand rather than by CI. That directory explains why.

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

None. This root uses the AWS provider only.

Repository settings need a repo-admin GitHub credential, which is exactly why
they are not here — see [`github/README.md`](./github/README.md).

## Running it

```bash
cd terraform
terraform init
terraform plan     # review carefully: this is where imports show up
terraform apply
```

`plan` and `import` only read AWS. Neither mutates the account — only `apply`
does.

## When CI fails on a missing IAM permission

The pipeline role grants a hand-written list of actions, so a change that
touches a resource in a way nothing has touched before can fail at `apply` with
`AccessDenied`. This happened once already, on `iam:UpdateAssumeRolePolicy`.

It cannot fix itself. Terraform updates a role before the inline policy attached
to it, so the failing resource is reached first and the run aborts before the
policy that would grant the permission is applied. `-target` does not help
either — it pulls dependencies in and tries to update them too.

Recovery needs credentials that already have the permission. Add the action to
the config first, then apply once from a workstation:

```bash
cd terraform
terraform init
terraform plan     # confirm it is only what you expect
terraform apply
```

Subsequent runs work from CI again, because the role now grants the action.

To keep everything in CI instead, grant just the missing action out-of-band and
re-run the failed workflow:

```bash
aws iam put-role-policy \
  --role-name seanteare-terraform \
  --policy-name bootstrap-missing-permission \
  --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"iam:UpdateAssumeRolePolicy","Resource":"*"}]}'
```

Delete it once the real policy has caught up, or it silently becomes permanent:

```bash
aws iam delete-role-policy \
  --role-name seanteare-terraform --policy-name bootstrap-missing-permission
```

### Adding a new IAM resource to this stack

Same shape, one step earlier. The pipeline role's IAM permissions are scoped to
the specific role and provider ARNs it owns, so a *new* role fails at
`CreateRole` — Terraform creates the role before it updates the policy that
would have allowed it.

**Renaming** an existing role is the same trap wearing a different hat: the new
name is a new ARN, so `CreateRole` is evaluated against a resource the policy
does not list yet.

Add the ARN to `data.aws_iam_policy_document.terraform` and apply that alone
first, from a workstation, then apply the role itself. Or do the whole thing
locally in one pass, which amounts to the same thing.

## Approving a queued apply

A workflow run holds the commit it was triggered for. The required-reviewer
rule means an apply can sit waiting for a while, and in that time `main` can
move on.

Approving a stale run therefore applies a stale tree: Terraform plans that older
config against the current live state, sees a difference, and reverts whatever
landed in between. It reports success, because it did exactly what its own
commit said.

This happened once. Two applies were approved a couple of minutes apart in the
wrong order, and the older one silently rolled back the IAM scoping the newer
one had just applied.

Two guards now exist, and neither removes the need to look:

- `terraform.yml` declares a `concurrency` group, so a run still waiting for
  approval is superseded when a newer one arrives instead of queueing behind it.
- The apply job refuses to run when its commit is not the current tip of `main`,
  and says which commit it expected.

**Check what you are approving.** The run's title names its commit. If it is not
the newest thing on `main`, cancel it and re-run Terraform from the current tip.

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
   available as Terraform outputs. Then apply [`github/`](./github/README.md),
   which creates the environments the workflows deploy through.
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
