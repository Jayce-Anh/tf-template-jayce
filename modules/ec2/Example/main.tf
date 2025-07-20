module "bastion" {
  source                     = "./modules/ec2"
  project                    = local.project
  tags                       = local.tags
  network                    = local.network
  enabled_eip                = true
  instance_type              = "t3a.small"
  instance_name              = "bastion"
  iops                       = 3000
  volume_size                = 30
  source_ingress_ec2_sg_cidr = ["0.0.0.0/0"]
  path_user_data             = "${path.root}/scripts/user_data/user_data.sh"
  key_name                   = "lab-jayce"
  subnet_id                  = local.network.public_subnet_ids[0] #use public subnet 
  alb_sg_id                  = module.alb.lb_sg_id

  sg_ingress = {
    rule1 = {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "Connect to bastion"
    },
    rule2 = {
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      description = "Connect to RDS MySQL"
    }
  }
}