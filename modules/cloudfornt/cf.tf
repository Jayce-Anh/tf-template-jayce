################################### CLOUDFRONT ###################################
#--------------------- Origin Access Identity --------------
resource "aws_cloudfront_origin_access_identity" "cf_oai" {
  comment = "${var.project.env}-${var.project.name}-${var.service_name}"
  lifecycle {
    create_before_destroy = true
  }
}

# ----------------- CloudFront Distribution -----------------
resource "aws_cloudfront_distribution" "cf_distribution" {
  origin {
    domain_name = aws_s3_bucket.s3.bucket_regional_domain_name
    origin_id = "${var.project.env}-${var.project.name}-${var.service_name}"
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.cf_oai.cloudfront_access_identity_path
    }
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  comment = "${var.project.env}-${var.project.name}-${var.service_name}"
  enabled = true
  default_root_object = "index.html"
  price_class = "PriceClass_All"
  aliases = [var.cloudfront_domain]
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "${var.project.env}-${var.project.name}-${var.service_name}"
    compress = true
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
#    function_association {
#      event_type   = "viewer-request"
#      function_arn = "arn:aws:cloudfront::752438478096:function/add-index-html"
#    }
    viewer_protocol_policy = "redirect-to-https"
    # viewer_protocol_policy = "allow-all"
    min_ttl = 60
    default_ttl = 3600
    max_ttl = 86400
  }
  viewer_certificate {
    acm_certificate_arn = var.cf_cert_arn
    ssl_support_method = "sni-only"
  }

  dynamic "custom_error_response" {
    for_each = var.custom_error_response

    content {
      error_code = custom_error_response.value["error_code"]

      response_code         = lookup(custom_error_response.value, "response_code", null)
      response_page_path    = lookup(custom_error_response.value, "response_page_path", null)
      error_caching_min_ttl = lookup(custom_error_response.value, "error_caching_min_ttl", null)
    }
  }
  depends_on = [aws_s3_bucket.s3]
}

#CloudFront Invalidation Policy
resource "aws_iam_policy" "invalidation" {
  name = format("%s-cloudfront-invalidation-policy", aws_cloudfront_distribution.cf_distribution.id)

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudfront:CreateInvalidation",
        ]
        Resource = [aws_cloudfront_distribution.cf_distribution.arn]
      },
    ]
  })
}

################################### S3 BUCKET ###################################
#--------------------- UI S3 Bucket ---------------------
#Create S3 Bucket
resource "aws_s3_bucket" "s3" {
  bucket = "${var.project.env}-${var.project.name}-${var.service_name}"
}

# resource "aws_s3_bucket_acl" "s3" {
#   bucket = aws_s3_bucket.s3.id
#   acl    = var.bucket_acl
# }

resource "aws_s3_bucket_versioning" "s3" {
  bucket = aws_s3_bucket.s3.id

  versioning_configuration {
    status     = lookup(var.versioning, "status", lookup(var.versioning, "enabled", "Enabled"))
    mfa_delete = lookup(var.versioning, "mfa_delete", null)
  }
}

#S3 Ownership Controls
resource "aws_s3_bucket_ownership_controls" "s3" {
  count = var.ownership_config != null ? 1 : 0

  bucket = aws_s3_bucket.s3.id

  rule {
    object_ownership = lookup(var.ownership_config, "object_ownership", "BucketOwnerPreferred")
  }
}

#----------------------- CloudFront S3 Bucket Policy -----------------------

#CloudFront S3 Bucket Policy
data "aws_iam_policy_document" "policy_doc" {
  # type = "CanonicalUser"
  # identifiers = ["FeCloudFrontOriginAccessIdentity.S3CanonicalUserId"]
  statement {
    principals {
      type = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.cf_oai.iam_arn]
    }
    effect = "Allow"
    actions = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.s3.arn}/*"]
  }
}

resource "aws_s3_bucket_policy" "policy" {
  bucket = aws_s3_bucket.s3.id
  policy = data.aws_iam_policy_document.policy_doc.json
}

#----------------------- S3 Full Access Policy -----------------------

#Full Access Policy
resource "aws_iam_policy" "full" {
  count = var.create_full_access_policy ? 1 : 0

  name        = format("%s-s3-full-access-policy", aws_s3_bucket.s3.id)
  description = format("%s-s3-full-access-policy", aws_s3_bucket.s3.id)
  path        = "/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:*",
        ]
        Effect = "Allow"
        Resource = [
          format("arn:aws:s3:::%s", aws_s3_bucket.s3.id),
          format("arn:aws:s3:::%s/*", aws_s3_bucket.s3.id),
        ]
      },
    ]
  })
}

output "full_access_policy_arn" {
  value = aws_iam_policy.full[0].arn
}



