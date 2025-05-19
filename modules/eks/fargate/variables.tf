variable "project" {
  type = object({
    env = string
    name = string
  })
}

variable "name" {
  type = string
  description = "Name of the EKS cluster"
}

variable "eks_version" {
  type = string
}

variable "eks_subnet" {
  type = list(string)
}

variable "fargates" {
  type = map(object({
    subnet_ids    = list(string)
    min-size      = number
    max_size      = number
    desired_size  = number
    instance_type = string
    disk_size     = number
    disk_type     = string
  }))
  default = {}
  description = "Map of Fargate profiles configurations"
}

variable "extra_iam_policies" {
  type    = list(string)
  default = []
}

variable "map_roles" {
  description = "A list of aws-auth config-map"
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

variable "addons" {
  type = list(object({
    name       = string
    version    = string
    role_arn   = optional(string)
  }))
  description = "List of EKS addons to be installed"
}

variable "cluster_sg_ids"{
  default = [] 
}

variable "map_users" {
  description = "A list of aws-auth config-map"
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

variable "vpc_id" {
  type = string
}

