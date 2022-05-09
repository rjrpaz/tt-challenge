# --- cdn/main.tf ---
resource "aws_cloudfront_distribution" "tt_distribution" {

  origin {
    domain_name = var.load_balancer_name
    origin_id   = var.load_balancer_domain
    
    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id   = var.load_balancer_domain

    forwarded_values {
      query_string = true

      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
  }
 
  price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "none"
      # restriction_type = "whitelist"
      # locations        = ["US", "BR", "AR"]
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}