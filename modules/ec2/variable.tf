#------------------------------------Project------------------------------------#
 variable "project" {
  type = object({
    name = string
    env  = string
    region = string
    account_id = number
  })
}

variable "tags" {
  type = object({
    Name = string
  })
}

#------------------------------------Network------------------------------------#
variable "network" {
  type = object({
    vpc_id             = string
    private_subnet_ids = list(string)
    public_subnet_ids  = list(string)
  })
}

#-------------------------------------EC2 instance------------------------------------#
variable "instance_type" {
  default = "t3.micro"
  type    = string
}

variable "iops" {
  type = number
}
variable "volume_size" {
  type = number
}

variable "source_ingress_ec2_sg_cidr" {
  type = list(string)
}

variable "enabled_eip" {
  type = bool
}

variable "instance_name" {
  type = string
}

variable "subnet_id" {}

variable "alb_sg_id" {
  type        = string
  default     = null
  description = "Security group ID of ALB (optional)"
}

# variable "path_public_key" {
#   type = string
#   description = "Path to import public key"
# }

variable "path_user_data" {
  type = string
  description = "Path to user data"
}

variable "key_name" {
  type = string
  description = "Name of the key pair"
}

# variable "path_public_key" {
#   type = string
#   description = "Path to public key"
# }

variable "sg_ingress" {
  type = map(object({
    from_port      = number
    to_port        = number
    protocol       = string
    description    = string
  }))
  description = "Map of ingress rules for EC2 security group"
}

