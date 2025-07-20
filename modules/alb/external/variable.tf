######################## ALB ########################
variable "project" {
  type = object({
    name = string
    env = string
  })
}

variable "tags" {
  type = object({
    Name = string
  })
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "dns_cert_arn" {
  type = string
  default = null
}

variable "source_ingress_sg_cidr" {
  type = list(string)
}

variable "lb_name" {
  type = string
}

#----------------------- Target Group -----------------------

variable "target_groups" {
  description = "Map of target groups to create"
  type = map(object({
    name             = string
    service_port     = number
    health_check_path = string
    priority         = number
    host_header      = string
    target_type      = string
    ec2_id           = string
  }))
  default = {}
}


