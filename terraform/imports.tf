/**
 * Adopt the existing bucket and distribution instead of creating new ones.
 *
 * This matters for CloudFront specifically: a replacement distribution gets a
 * NEW *.cloudfront.net domain name and takes 15-20 minutes to deploy, and the
 * aliases have to be detached from the old one first. Importing keeps
 * d37bn061td3s3q.cloudfront.net and turns the OAC/TLS work into an in-place
 * update.
 *
 * IDs are literals on purpose — import blocks are evaluated before most
 * expressions resolve, and a hardcoded ID is the one thing that always works.
 *
 * After the first successful apply these blocks are inert and can be deleted.
 */

import {
  to = aws_s3_bucket.site
  id = "seanteare.com"
}

import {
  to = aws_cloudfront_distribution.site
  id = "E187XNVZFLAXPG"
}

# NOT imported, deliberately:
#   aws_s3_bucket_policy            - PutBucketPolicy is an upsert; create overwrites
#   aws_s3_bucket_public_access_block - same, PutPublicAccessBlock is an upsert
# Both are singletons per bucket, so "creating" them replaces what is there.
