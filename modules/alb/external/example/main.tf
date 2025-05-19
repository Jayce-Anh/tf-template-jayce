module "external_lb" {
  source                 = "./modules/alb/external"
  project                = local.project
  lb_name                = "ex-alb"
  vpc_id                 = local.network.vpc_id
  dns_cert_arn           = module.acm.cert_arn
  subnet_ids             = local.network.public_subnet_id
  source_ingress_sg_cidr = ["0.0.0.0/0"]
  
  target_groups = {
    app1 = {
      name             = "app1"
      service_port     = 8080
      health_check_path = "/health"
      priority         = 100
      host_header      = "app1.example.com"
      ec2_id           = aws_instance.app1.id
    },
    app2 = {
      name             = "app2"
      service_port     = 8081
      health_check_path = "/healthz"
      priority         = 200
      host_header      = "app2.example.com"
      ec2_id           = aws_instance.app2.id
    }
  }
}