variable "project" {
  type = object({
    name = string
    env = string
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
}

variable "source_ingress_sg_cidr" {
  type = list(string)
}

variable "lb_name" {
  type = string
}


