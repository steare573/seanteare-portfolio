output "nameservers" {
  description = <<-EOT
    The four Route 53 nameservers. Paste these into Namecheap under
    Domain > Nameservers > Custom DNS to complete the DNS migration.
    Nothing moves until you do.
  EOT
  value = aws_route53_zone.site.name_servers
}

output "zone_id" {
  description = "Route 53 hosted zone ID."
  value       = aws_route53_zone.site.zone_id
}

output "cloudfront_domain" {
  description = "Distribution domain. Unchanged by this config because the distribution is imported."
  value       = aws_cloudfront_distribution.site.domain_name
}

output "cloudfront_distribution_id" {
  description = "Distribution ID — used by the deploy workflow for invalidations."
  value       = aws_cloudfront_distribution.site.id
}

output "certificate_arn" {
  description = "Validated ACM certificate serving the aliases."
  value       = aws_acm_certificate_validation.site.certificate_arn
}

output "site_bucket" {
  description = "Bucket the deploy workflow syncs into."
  value       = aws_s3_bucket.site.id
}

output "deploy_role_arn" {
  description = "Set as AWS_DEPLOY_ROLE_ARN in the repo's Actions variables."
  value       = aws_iam_role.deploy.arn
}

output "terraform_role_arn" {
  description = "Set as AWS_TERRAFORM_ROLE_ARN in the repo's Actions variables."
  value       = aws_iam_role.terraform.arn
}
