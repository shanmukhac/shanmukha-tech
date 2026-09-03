terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket       = "shanmukha-tech-statelocking"
    key          = "portfolio/terraform.tfstate"
    region       = "ap-south-1"
    use_lockfile = true
    encrypt      = true
  }
}

provider "aws" {
  region = "ap-south-1"
}

provider "aws" {
  alias  = "virginia"
  region = "us-east-1"
}


resource "aws_s3_bucket" "websiteHosting" {
  bucket = "portfolio-website-shanmukha-tech"

  tags = {
    Name        = "portfolio"
    Environment = "prd"
  }
}

data "aws_route53_zone" "tech" {
  name         = "shanmukha.tech"
  private_zone = false
}

# resource "aws_acm_certificate" "cert" {
#   provider = aws.virginia

#   domain_name       = "shanmukha.tech"

#   subject_alternative_names = [
#     "shanmukhas.in"
#   ]

#   validation_method = "DNS"

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# resource "aws_acm_certificate_validation" "cert_validation" {
#   provider = aws.virginia

#   certificate_arn = aws_acm_certificate.cert.arn
# }

data "aws_acm_certificate" "existing_cert" {
  provider = aws.virginia

  domain = "shanmukha.tech"

  statuses = ["ISSUED"]

  most_recent = true
}

resource "aws_cloudfront_distribution" "websiteDistribution" {
  origin {
    domain_name = aws_s3_bucket.websiteHosting.bucket_regional_domain_name
    origin_id   = "S3-portfolio-website-shanmukha-tech"

    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Portfolio Website Distribution"
  default_root_object = "index.html"

  aliases = [
    "shanmukha.tech"
  ]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-portfolio-website-shanmukha-tech"

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
    acm_certificate_arn      = data.aws_acm_certificate.existing_cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

resource "aws_route53_record" "tech_ipv4" {
  zone_id = data.aws_route53_zone.tech.zone_id
  name    = "shanmukha.tech"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.websiteDistribution.domain_name
    zone_id                = aws_cloudfront_distribution.websiteDistribution.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "tech_ipv6" {
  zone_id = data.aws_route53_zone.tech.zone_id
  name    = "shanmukha.tech"
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.websiteDistribution.domain_name
    zone_id                = aws_cloudfront_distribution.websiteDistribution.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "portfolio-website-shanmukha-tech-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"

}

resource "aws_s3_object" "portfolioSite" {

  for_each = fileset("${path.module}/shanmukha-tech", "**/*")
  bucket   = aws_s3_bucket.websiteHosting.bucket
  key      = each.value
  source   = "${path.module}/shanmukha-tech/${each.value}"
  etag     = filemd5("${path.module}/shanmukha-tech/${each.value}")

  content_type = lookup(local.mime_types, reverse(split(".", each.value))[0], "application/octet-stream")
}

resource "aws_s3_bucket_policy" "s3_policy" {
  bucket = aws_s3_bucket.websiteHosting.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "Statement1",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "cloudfront.amazonaws.com"
        },
        "Action" : [
          "s3:GetObject",
          # "s3:ListBucket"
        ],
        "Resource" : "${aws_s3_bucket.websiteHosting.arn}/*"

        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.websiteDistribution.arn
          }
        }
      }
    ]
  })
}