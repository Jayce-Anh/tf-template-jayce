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

variable "eks_name" {
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
  description = "Map of EKS node group configurations"
  type = map(object({
    subnet_ids     = list(string)
    min_size       = number
    max_size       = number
    desired_size   = number
    instance_type  = optional(string)        # Use for single instance type
    instance_types = optional(list(string))  # Use for multiple instance types (recommended for SPOT)
    capacity_type  = optional(string)        # "ON_DEMAND" or "SPOT"
    disk_size      = number
    disk_type      = string
    ami_type       = optional(string)
    key_name       = optional(string)
    labels         = optional(map(string))
    ingress_rules  = optional(map(object({
      from_port                = number
      to_port                  = number
      protocol                 = string
      cidr_blocks             = optional(list(string))
      source_security_group_id = optional(string)
      self                    = optional(bool)
      description             = optional(string)
    })), {})
    tags = optional(map(string))
  }))
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

variable "eks_sg_ingress" {
  description = "Extra security group ingress rules for EKS cluster"
  type = object({
    ingress_rules = optional(map(object({
      from_port                = number
      to_port                  = number
      protocol                 = string
      cidr_blocks             = optional(list(string))
      source_security_group_id = optional(string)
      self                    = optional(bool)
      description             = optional(string)
    })), {})
  })
  default = {
    ingress_rules = {}
  }
}

variable "addons" {
  description = "List of EKS addons to install"
  type = list(object({
    name    = string
    version = optional(string)
  }))
  default = []
}

variable "endpoint_public_access" {
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled"
  type        = bool
  default     = false
}

variable "endpoint_private_access" {
  description = "Indicates whether or not the Amazon EKS private API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "endpoint_public_access_cidrs" {
  description = "List of CIDR blocks which can access the Amazon EKS public API server endpoint. Ignored when endpoint_public_access is false"
  type        = list(string)
  default     = null
}




