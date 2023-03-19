resource "aws_s3_bucket" "origin" {
  bucket = "${var.settings-name_prefix}-host-bucket"

  tags = {
    Name = "${var.settings-name_prefix}-host-bucket"
  }
}


resource "aws_s3_bucket_ownership_controls" "example" {
  bucket = aws_s3_bucket.origin.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}


resource "aws_s3_bucket_public_access_block" "example" {
  bucket                  = aws_s3_bucket.origin.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}


resource "aws_s3_bucket_versioning" "example" {
  bucket = aws_s3_bucket.origin.id

  versioning_configuration {
    status = "Disabled"
  }
}


resource "aws_s3_bucket_website_configuration" "example" {
  bucket = aws_s3_bucket.origin.id

  index_document {
    suffix = var.web_host_html_list.index_document
  }
}

resource "aws_s3_object" "example" {
  for_each = var.web_host_html_list
  bucket = aws_s3_bucket.origin.id
  key    = each.value
  source = "../../src/${each.value}"
  content_type = "text/html"
}

resource "aws_s3_bucket_cors_configuration" "example" {
  bucket = aws_s3_bucket.origin.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = var.allowed_cors_origins
    expose_headers  = []
    max_age_seconds = 3000
  }
}


resource "aws_s3_bucket_policy" "example" {
  bucket = aws_s3_bucket.origin.id
  policy = jsonencode({

    Version   = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = {
          Service = ["cloudfront.amazonaws.com"]
        },
        Action    = ["s3:GetObject"],
        Resource  = "${aws_s3_bucket.origin.arn}/*",
        Condition = {
          StringEquals = {
            "aws:SourceArn" = aws_cloudfront_distribution.example.arn
          }
        }
      }
    ]
  })
  depends_on = [
    aws_s3_bucket.origin,
  ]

}


resource "aws_cloudfront_distribution" "example" {
  enabled = true
  web_acl_id = var.web_host_waf_arn

  origin {

    origin_id = aws_s3_bucket.origin.id

    domain_name = aws_s3_bucket.origin.bucket_regional_domain_name

    origin_access_control_id = aws_cloudfront_origin_access_control.example.id
  }
  default_root_object = var.web_host_html_list.index_document
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  default_cache_behavior {
    target_origin_id       = aws_s3_bucket.origin.id
    viewer_protocol_policy = "allow-all"
    cached_methods         = ["GET", "HEAD"]
    allowed_methods        = ["GET", "HEAD"]

    cache_policy_id            = data.aws_cloudfront_cache_policy.caching_disabled.id
    origin_request_policy_id   = data.aws_cloudfront_origin_request_policy.example.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.example.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  custom_error_response {
    error_caching_min_ttl = 300
    error_code            = 403
    response_code         = 403
    response_page_path    = "/error.html"
  }
}

data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_origin_request_policy" "example" {
  name = "Managed-CORS-S3Origin"
}


resource "aws_cloudfront_response_headers_policy" "example" {

  name    = "example"
  comment = "Allow from limited origins"

  cors_config {
    access_control_allow_credentials = false

    access_control_allow_headers {
      items = ["*"]
    }

    access_control_allow_methods {
      items = ["GET", "HEAD"]
    }

    access_control_allow_origins {
      items = var.allowed_cors_origins
    }

    origin_override = true
  }
}


resource "aws_cloudfront_origin_access_control" "example" {
  name                              = "${var.settings-name_prefix}-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}


resource "aws_s3_bucket" "waf_logs" {
  bucket = "aws-waf-logs-${var.settings-name_prefix}-s3"

  tags = {
    Name = "${var.settings-name_prefix}-waf-logs-s3"
  }

}


resource "aws_s3_bucket_ownership_controls" "waf_logs" {
  bucket = aws_s3_bucket.waf_logs.id


  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}


resource "aws_s3_bucket_public_access_block" "waf_logs" {
  bucket = aws_s3_bucket.origin.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}


