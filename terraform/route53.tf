/**
 * Public hosted zone for the domain.
 *
 * Creating this zone does NOT move DNS by itself — the domain keeps resolving
 * through Namecheap until the nameservers at the registrar are changed to the
 * four in the `nameservers` output. That gives us a safe ordering: create the
 * zone, mirror every existing record into it, verify, and only then cut over.
 *
 * Deleting and recreating this zone assigns a DIFFERENT set of nameservers and
 * would take the domain offline until the registrar is updated again.
 */
resource "aws_route53_zone" "site" {
  name    = var.domain_name
  comment = "Managed by Terraform - ${var.github_repo}"

  lifecycle {
    prevent_destroy = true
  }
}

# ---------------------------------------------------------------------------
# Site records -> CloudFront
# ---------------------------------------------------------------------------

# Alias records, not CNAMEs. A CNAME is illegal at the zone apex; Route 53
# alias records are the standard workaround and are not billed for queries.
resource "aws_route53_record" "apex_a" {
  zone_id = aws_route53_zone.site.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "apex_aaaa" {
  zone_id = aws_route53_zone.site.zone_id
  name    = var.domain_name
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www_a" {
  zone_id = aws_route53_zone.site.zone_id
  name    = var.www_domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www_aaaa" {
  zone_id = aws_route53_zone.site.zone_id
  name    = var.www_domain
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
    evaluate_target_health = false
  }
}

# ---------------------------------------------------------------------------
# Preserved records
#
# Read from the live Namecheap zone before migration. Changing nameservers
# moves DNS wholesale, so anything not recreated here stops resolving the
# moment the cutover happens. Email is the one that fails silently.
# ---------------------------------------------------------------------------

resource "aws_route53_record" "mx" {
  zone_id = aws_route53_zone.site.zone_id
  name    = var.domain_name
  type    = "MX"
  ttl     = 3600
  records = var.email_forwarding_mx
}

resource "aws_route53_record" "txt" {
  zone_id = aws_route53_zone.site.zone_id
  name    = var.domain_name
  type    = "TXT"
  ttl     = 3600
  records = var.txt_records
}
