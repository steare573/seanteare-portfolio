# Must be us-east-1 — CloudFront will not accept a certificate from any other
# region. This is the single most common failure in this setup.
resource "aws_acm_certificate" "site" {
  provider = aws.us_east_1

  domain_name               = var.domain_name
  subject_alternative_names = [var.www_domain]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Because the zone is managed here too, validation is fully automatic. If DNS
# had stayed at Namecheap, this apply would hang until the CNAME was added by
# hand — that is the main reason to move the zone.
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.site.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id         = aws_route53_zone.site.zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
  allow_overwrite = true
}

# Blocks until ACM observes the DNS records and issues. Typically a few minutes;
# the timeout guards against a nameserver switch that has not propagated yet.
resource "aws_acm_certificate_validation" "site" {
  provider = aws.us_east_1

  certificate_arn         = aws_acm_certificate.site.arn
  validation_record_fqdns = [for r in aws_route53_record.cert_validation : r.fqdn]

  timeouts {
    create = "20m"
  }
}
