provider "aws" {
  alias  = "acm_region"
  region = var.region
}

resource "aws_acm_certificate" "cert" {
  provider          = aws.acm_region
  domain_name       = var.domain
  validation_method = "DNS"
  
  lifecycle {
    create_before_destroy = true # Ensure new certificate is created before destroying old one
  }

  tags = merge(var.tags, {
    Name = "${var.project.env}-${var.project.name}-${var.region}-cert"
  })
}