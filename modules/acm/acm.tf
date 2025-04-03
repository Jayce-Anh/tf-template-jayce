resource "aws_acm_certificate" "cert" {
  domain_name       = var.domain
  validation_method = "DNS"
  
  lifecycle {
    create_before_destroy = true # Ensure new certificate is created before destroying old one
  }
}