resource "aws_s3_bucket" "site" {
  bucket = var.bucket_name

  # Pre-existing tag, kept deliberately. provider default_tags replace the tag
  # set rather than merging with untracked tags, so without this line the
  # apply would silently strip it.
  tags = {
    site = "seanteare.com"
  }

  # The bucket predates this config and holds the live site. Losing it would
  # mean re-pointing the distribution, so make `terraform destroy` refuse.
  lifecycle {
    prevent_destroy = true
  }
}

# Stays fully locked down. Under Origin Access Control the bucket is never
# public — CloudFront authenticates as a service principal. This is the setting
# that currently returns 403 on the old website-endpoint setup, and with OAC we
# get to leave it on.
resource "aws_s3_bucket_public_access_block" "site" {
  bucket = aws_s3_bucket.site.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "site" {
  bucket = aws_s3_bucket.site.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Cheap insurance: a bad `s3 sync --delete` is recoverable.
resource "aws_s3_bucket_versioning" "site" {
  bucket = aws_s3_bucket.site.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Expire old versions so versioning does not grow unbounded.
resource "aws_s3_bucket_lifecycle_configuration" "site" {
  bucket     = aws_s3_bucket.site.id
  depends_on = [aws_s3_bucket_versioning.site]

  rule {
    id     = "expire-noncurrent-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "site" {
  bucket = aws_s3_bucket.site.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Grants read to this distribution and nothing else. Replaces the old
# "Principal: *" public-read policy.
data "aws_iam_policy_document" "site_bucket" {
  statement {
    sid     = "AllowCloudFrontServicePrincipalReadOnly"
    effect  = "Allow"
    actions = ["s3:GetObject"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    resources = ["${aws_s3_bucket.site.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.site.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id
  policy = data.aws_iam_policy_document.site_bucket.json

  # Without this the policy can land while public access is still permitted.
  depends_on = [aws_s3_bucket_public_access_block.site]
}
