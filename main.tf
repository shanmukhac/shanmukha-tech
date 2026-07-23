terraform {
  required_providers {
    aws = {
        version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

# provider "aws" {
#   alias  = "virginia"
#   region = "us-east-1"
# }

resource "aws_s3_bucket" "websiteHosting" {
  bucket = "portfolio-website-one"

  tags = {
    Name        = "portfolio"
    Environment = "prd"
  }
}

# resource "aws_acm_certificate" "cert" {
#   provider = aws.virginia

#   domain_name       = "somala.co.in"
#   validation_method = "DNS"
# }

resource "aws_cloudfront_distribution" "websiteDistribution" {
  origin {
    domain_name = aws_s3_bucket.websiteHosting.bucket_regional_domain_name
    origin_id   = "S3-portfolio-website-one"

    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Portfolio Website Distribution"
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-portfolio-website-one"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "aws_cloudfront_origin_access_control" "oac" {
  name = "portfolio-website-one-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior = "always"
  signing_protocol = "sigv4"
  
}

resource "aws_s3_object" "portfolioSite" {

  for_each = fileset("${path.module}/NewPortfolio","**/*")
  bucket = aws_s3_bucket.websiteHosting.bucket
  key    = each.value
  source = "${path.module}/NewPortfolio/${each.value}"
  etag   = filemd5("${path.module}/NewPortfolio/${each.value}")

  content_type = lookup(local.mime_types, reverse(split(".", each.value))[0],"application/octet-stream")
}

resource "aws_s3_bucket_policy" "s3_policy" {
  bucket = aws_s3_bucket.websiteHosting.id
  policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Statement1",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudfront.amazonaws.com"
      },
      "Action": [
        "s3:GetObject",
        # "s3:ListBucket"
      ],
      "Resource": "${aws_s3_bucket.websiteHosting.arn}/*"

      Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.websiteDistribution.arn
          }
        }
    }
  ]
})
}