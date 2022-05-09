# --- cdn/output.tf ---

output "cdn_domain_name" {
  value = aws_cloudfront_distribution.tt_distribution.domain_name
}

