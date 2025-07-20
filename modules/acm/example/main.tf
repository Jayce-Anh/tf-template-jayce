#Certificate for ALB
module "acm_alb" {
  source  = "./modules/acm"
  project = local.project
  tags    = local.tags
  domain  = "*.jayce-lab.work"
  region  = local.project.region
}

#Certificate for CloudFront
module "acm_s3cf" {
  source  = "./modules/acm"
  project = local.project
  tags    = local.tags
  domain  = "*.jayce-lab.work"
  region  = "us-east-1"
}