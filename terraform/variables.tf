variable "aws_region" {
  description = "Region for the content bucket. The bucket already lives in us-east-1."
  type        = string
  default     = "us-east-1"
}

variable "domain_name" {
  description = "Apex domain served by CloudFront."
  type        = string
}

variable "www_domain" {
  description = "www alias. Added to the certificate and as a Route 53 alias record."
  type        = string
}

variable "bucket_name" {
  description = "Existing S3 bucket holding the built site. Imported, not created."
  type        = string
}

variable "distribution_id" {
  description = "Existing CloudFront distribution. Imported so the domain name is preserved."
  type        = string
}

variable "github_repo" {
  description = "owner/repo allowed to assume the CI roles via OIDC."
  type        = string
}

variable "github_branch" {
  description = "Branch allowed to assume the CI roles. Deploys are gated to this branch."
  type        = string
  default     = "main"
}

variable "github_environment" {
  description = <<-EOT
    GitHub Actions environment used by the deploy and apply jobs. This has to be
    in the OIDC trust policy: when a job declares `environment:`, GitHub swaps
    the token's `sub` claim from the ref form to
    `repo:<owner>/<repo>:environment:<name>`, so a ref-only trust policy fails
    to assume.
  EOT
  type        = string
  default     = "production"
}

variable "price_class" {
  description = "CloudFront edge coverage. PriceClass_100 is North America + Europe and is the cheapest."
  type        = string
  default     = "PriceClass_100"
}

variable "email_forwarding_mx" {
  description = <<-EOT
    MX records to preserve when DNS moves to Route 53. These are Namecheap's
    email-forwarding hosts, read from the live zone before migration. Dropping
    them silently breaks mail to the domain.
  EOT
  type        = list(string)
  default = [
    "10 eforward1.registrar-servers.com",
    "10 eforward2.registrar-servers.com",
    "10 eforward3.registrar-servers.com",
    "15 eforward4.registrar-servers.com",
    "20 eforward5.registrar-servers.com",
  ]
}

variable "txt_records" {
  description = "Apex TXT records to preserve (SPF for the forwarder, plus site verification)."
  type        = list(string)
  default = [
    "v=spf1 include:spf.efwd.registrar-servers.com ~all",
    "google-site-verification=pBeJ6_H3U6ZgQqwqzC1nSSY8jhqD1eEYtH1bWL406zE",
  ]
}
