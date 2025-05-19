#-------------------Initial terraform tfstate configuration -------------------#
terraform {
  backend "s3" {
    bucket = "lab-jaeger-terraform-state"
    key    = "lab/terraform.tfstate"
    region = "ap-southeast-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    #     sops = {
    #       source  = "carlpett/sops"
    #       version = ">= 0.7"
    #     }
  }
}

#-------------------Project configuration-------------------#
#Common configuration
locals {
  project = {
    name       = "terraform"
    env        = "lab"
    region     = "ap-southeast-1"
    account_id = "325842618176"
  }
  #Network configuration
  network = {
    vpc_id            = "${module.vpc.vpc_id}"
    public_subnet_id  = "${module.vpc.public_subnet_ids}"
    private_subnet_id = "${module.vpc.private_subnet_ids}"
  }
  #Tags configuration
  tags = {
    project = "${local.project.name}"
    env     = "${local.project.env}"
  }
  #Git configuration
    git_repo = {
    fe = {
      url = "https://github.com/kasta-sotatek/example-fe"
      name = "example-fe"
      branch = "develop"
    }
    be = {
      url = "https://github.com/kasta-sotatek/example-be"
      name = "example-be"
      branch = "develop"
    }
  }
}


provider "aws" {
  region = local.project.region
}
