module "cloudfront" {
  source            = "./modules/cloudfront"
  project           = local.project
  service_name      = "kasta-fe"
  cf_cert_arn       = module.acm_s3cf.cert_arn
  cloudfront_domain = "dev-fe.kasta.sotatek.works"
  custom_error_response = {
    "403" = {
      error_code = 403
      response_code = 200
      response_page_path = "/index.html"
    }
  }
}