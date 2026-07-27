# AWS-managed policies. Using these avoids hand-rolling cache keys and header
# sets, and they are kept current by AWS.
data "aws_cloudfront_cache_policy" "optimized" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_response_headers_policy" "security" {
  name = "Managed-SecurityHeadersPolicy"
}

# Replaces public bucket access. CloudFront signs origin requests with SigV4 as
# the cloudfront.amazonaws.com service principal.
resource "aws_cloudfront_origin_access_control" "site" {
  name                              = "${var.domain_name}-oac"
  description                       = "OAC for ${var.bucket_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_function" "rewrite_index" {
  name    = "rewrite-index"
  runtime = "cloudfront-js-2.0"
  comment = "Append index.html to directory-style routes for the S3 REST origin"
  publish = true
  code    = file("${path.module}/functions/rewrite-index.js")
}

resource "aws_cloudfront_distribution" "site" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.domain_name} static site"
  default_root_object = "index.html"
  price_class         = var.price_class

  aliases = [var.domain_name, var.www_domain]

  origin {
    # Regional REST endpoint, NOT the s3-website-* endpoint. The website
    # endpoint cannot authenticate callers and only speaks HTTP; this one
    # supports OAC and is HTTPS end to end.
    domain_name              = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id                = "s3-${var.bucket_name}"
    origin_access_control_id = aws_cloudfront_origin_access_control.site.id
  }

  default_cache_behavior {
    target_origin_id = "s3-${var.bucket_name}"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]

    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    cache_policy_id            = data.aws_cloudfront_cache_policy.optimized.id
    response_headers_policy_id = data.aws_cloudfront_response_headers_policy.security.id

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.rewrite_index.arn
    }
  }

  # S3 returns 403 (not 404) for a missing key when the caller lacks
  # s3:ListBucket, which is intentional here — so both map to the 404 page.
  custom_error_response {
    error_code            = 403
    response_code         = 404
    response_page_path    = "/404.html"
    error_caching_min_ttl = 60
  }

  custom_error_response {
    error_code            = 404
    response_code         = 404
    response_page_path    = "/404.html"
    error_caching_min_ttl = 60
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.site.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}
