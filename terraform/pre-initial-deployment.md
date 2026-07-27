# Pre-Initial-Deployment Runbook

What has to happen before `seanteare.com` serves this site, and why the first
Terraform run cannot be a CI run.

Read this once end to end before starting. Several steps block on external
propagation and are painful to interleave.

---

## The short answer

**One local Terraform run is required.** After that, CI owns the stack
permanently and the local checkout becomes optional.

## Why CI cannot do the first run

Three hard dependencies, in order:

1. **The state bucket must exist before `terraform init`.** The S3 backend
   cannot create the bucket that stores its own state. Something has to make
   `seanteare-tfstate` first.

2. **The pipeline's identity is created by this Terraform.** `terraform.yml`
   authenticates by assuming `AWS_TERRAFORM_ROLE_ARN`, but that role — and the
   OIDC provider that lets GitHub assume it — are resources in
   `github_oidc.tf`. CI cannot authenticate until the thing it authenticates
   with exists.

3. **The Actions variables come from Terraform outputs.**
   `AWS_TERRAFORM_ROLE_ARN`, `AWS_DEPLOY_ROLE_ARN`, `AWS_SITE_BUCKET`, and
   `AWS_DISTRIBUTION_ID` are all `terraform output` values. There is nothing to
   configure in GitHub until after the first apply.

A fourth, softer reason: `aws_acm_certificate_validation` blocks until DNS
resolves through Route 53, which requires changing nameservers at the registrar
**mid-apply**. A CI job would sit there and hit the 20-minute timeout. The first
run is inherently interactive.

### The escape hatch, and why to skip it

You could create the state bucket, OIDC provider, and role by hand in the
console and let CI do the rest. That is the same manual work relocated to a GUI,
and it produces resources Terraform does not manage — so they drift and nobody
remembers why they exist.

The other option, a static access key in repo secrets for the first run, trades
a one-time local apply for a long-lived credential living in GitHub. Worse
trade.

One local bootstrap is the normal, correct shape.

---

## Credentials

The `seanteare-ro` profile is **read-only by design** and every write will 403.
The first apply needs admin or power-user credentials.

```bash
aws configure --profile seanteare-admin
export AWS_PROFILE=seanteare-admin
aws sts get-caller-identity   # confirm before proceeding
```

`terraform plan` and `terraform import` only read AWS. Neither mutates the
account — only `apply` does. Planning with the read-only profile is a safe way
to preview the diff first.

---

## Checklist

### 0. Clear the WHOIS hold at the registrar

- [ ] Log into Namecheap → Domain List → `seanteare.com`
- [ ] Complete registrant contact verification
- [ ] Confirm: `dig NS seanteare.com` no longer returns
      `failed-whois-verification.namecheap.com`

**Nothing downstream works until this clears.** The domain currently resolves to
a Namecheap parking page, not CloudFront, and port 443 refuses connections
entirely.

### 1. Create the state bucket

```bash
aws s3 mb s3://seanteare-tfstate --region us-east-1
aws s3api put-bucket-versioning --bucket seanteare-tfstate \
  --versioning-configuration Status=Enabled
aws s3api put-public-access-block --bucket seanteare-tfstate \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
```

### 2. Capture the live DNS zone before touching anything

Changing nameservers moves DNS **wholesale**. Anything not recreated in Route 53
stops resolving the moment the cutover lands. Email fails silently.

```bash
dig seanteare.com MX +short
dig seanteare.com TXT +short
dig www.seanteare.com +short
```

- [ ] Compare against `email_forwarding_mx` and `txt_records` in `variables.tf`
- [ ] Add anything missing

The values in `variables.tf` were captured while the domain was parked, and a
parked zone may not expose every record. Cross-check against the Namecheap DNS
panel, not just `dig`.

### 3. First apply

```bash
cd terraform
terraform init
terraform plan      # review the imports carefully
terraform apply
```

Expect the apply to **pause** at `aws_acm_certificate_validation`. That is
correct — ACM cannot see the validation records until DNS actually moves. Leave
it running or interrupt it; either way step 5 resumes from where it stopped.

### 4. Switch nameservers

```bash
terraform output nameservers
```

- [ ] Namecheap → Domain List → Manage → **Nameservers** → **Custom DNS**
- [ ] Paste all four (they look like `ns-1234.awsdns-56.org`)
- [ ] Wait for propagation — usually 30 min to a few hours; 48 h is the outer bound
- [ ] Confirm: `dig NS seanteare.com` returns `awsdns` hosts

**Verify Route 53 answers correctly before cutting over**, by querying it
directly while Namecheap is still authoritative:

```bash
NS=$(terraform output -json nameservers | python3 -c 'import json,sys;print(json.load(sys.stdin)[0])')
dig @"$NS" seanteare.com MX
dig @"$NS" www.seanteare.com
```

### 5. Finish the apply

```bash
terraform apply
```

ACM sees the validation records, issues the certificate, and CloudFront picks it
up. Distribution updates take 10–20 minutes to reach all edges.

### 6. Wire up GitHub

Repo → Settings → Secrets and variables → Actions → **Variables** (not secrets;
none of these are sensitive):

| Variable | Source |
|---|---|
| `AWS_TERRAFORM_ROLE_ARN` | `terraform output terraform_role_arn` |
| `AWS_DEPLOY_ROLE_ARN` | `terraform output deploy_role_arn` |
| `AWS_SITE_BUCKET` | `terraform output site_bucket` |
| `AWS_DISTRIBUTION_ID` | `terraform output cloudfront_distribution_id` |

- [ ] Create a `production` environment and add required reviewers, so an apply
      cannot reach production unattended

### 7. Point the site at the new domain

- [ ] `astro.config.mjs`: remove `base`, set `site = "https://seanteare.com"`

  **Required.** Without it every asset URL keeps the `/seanteare-portfolio/`
  prefix and the site 404s completely.

- [ ] Add `src/pages/404.astro` so the CloudFront 403/404 error mapping has a
      page to serve
- [ ] `npm run build && npm run preview` — verify locally

### 8. Deploy and cut over

- [ ] Run `deploy-aws.yml` manually (`workflow_dispatch`)
- [ ] Verify `https://seanteare.com`, `https://www.seanteare.com`, a deep route
      like `/blog/agentic-workflows`, and the résumé PDF
- [ ] Confirm HTTP redirects to HTTPS and the certificate is valid
- [ ] Change `deploy-aws.yml` from `workflow_dispatch` to `push: branches: [main]`
- [ ] Delete `.github/workflows/deploy.yml` (the GitHub Pages workflow)

### 9. Cleanup

```bash
aws s3api delete-bucket-website --bucket seanteare.com   # unused under OAC
```

- [ ] Delete `terraform/imports.tf` — inert once the resources are in state

---

## After this, CI owns everything

Push a change under `terraform/` and the pipeline plans and applies it,
authenticated by OIDC with no stored keys. Push anything else and the site
rebuilds and deploys.

## Rollback

The bucket has versioning enabled, so a bad `s3 sync --delete` is recoverable.
`prevent_destroy` is set on the bucket, distribution, and hosted zone — a
`terraform destroy` refuses rather than taking the domain offline.

If the cutover goes wrong, reverting nameservers at Namecheap restores the
previous DNS, subject to propagation delay.

## Known gotchas

- **ACM certificates for CloudFront must live in us-east-1.** The aliased
  provider in `providers.tf` handles this; do not "simplify" it away.
- **Deleting and recreating the Route 53 zone assigns different nameservers**
  and takes the domain offline until the registrar is updated again.
- **Namecheap email forwarding may assume Namecheap DNS.** The MX records keep
  pointing at `eforward*` hosts from Route 53 and that generally works, but
  confirm with their support, or move email to a real provider as part of this.
