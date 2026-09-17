output "cloudfront_distribution_id" {
    description = "The ID of the CloudFront distribution"
    value = aws_cloudfront_distribution.websiteDistribution.id
}