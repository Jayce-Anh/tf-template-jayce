variable "project" {
  type = object({
    env = string
    name = string
  })
}

variable "tags" {
  type = object({
    Name = string
  })
}

variable "name" {
  type = string
}

variable "eks_version" {
  type = string
}

variable "eks_vpc" {
  type = string
}

variable "eks_subnet" {
  type = list(string)
}

variable "fargates" {
  type    = any
  default = {}
}

variable "node_groups" {
  type    = any
  default = {}
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
  type        = any
  description = "Addons(vpc-cni, coredns,  aws-ebs-csi-driver and on)"
  default = {}
}

variable "cluster_ingress" {
  description = "Map of ingress rules to add to the EKS cluster security group"
  type        = map(any)
  default     = {}
}

variable "node_group_ingress" {
  description = "Map of ingress rules to add to the EKS node group security group"
  type        = map(any)
  default     = {}
}





