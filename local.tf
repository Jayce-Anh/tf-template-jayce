#-------------------Initial terraform tfstate configuration -------------------#
terraform {
  backend "s3" {
    bucket = "lab-jayce-terraform-state"
    key    = "lab/terraform.tfstate"
    region = "ap-southeast-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
    #     sops = {
    #       source  = "carlpett/sops"
    #       version = ">= 0.7"
    #     }
  }
}

#-------------------Project configuration-------------------#
locals {
  # Project configuration
  project = {
    name       = "todo"
    env        = "lab"
    region     = "ap-southeast-1"
    account_id = "680993828488"
  }
  # Network configuration
  network = {
    vpc_id             = module.vpc.vpc_id
    public_subnet_ids  = module.vpc.public_subnet_ids
    private_subnet_ids = module.vpc.private_subnet_ids
  }

  # Tags configuration
  tags = {
    Name = "${local.project.env}-${local.project.name}"
    env  = "${local.project.env}"
  }

  # Git configuration
  git_repo = {
    fe = {
      url          = "https://github.com/Jayce-Anh/todo_app-fe.git"
      name         = "todo_app-fe"
      branch       = "main"
      organization = "Jayce-Anh"
    }
    be = {
      url          = "https://github.com/Jayce-Anh/todo_app-be.git"
      name         = "todo_app-be"
      branch       = "main"
      organization = "Jayce-Anh"
    }
  }
}