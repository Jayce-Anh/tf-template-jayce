#------------------------------------Project------------------------------------#
 variable "project" {
  type = object({
    name = string
    env  = string
    region = string
    account_id = number
  })
}

#------------------------------------Network------------------------------------#
variable "network" {
  type = object({
    vpc_id             = string
    private_subnet_id = list(string)
    public_subnet_id  = list(string)
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

variable "path_user_data" {
  type        = string
  description = "Path to file.sh has content of user_data"
  default     = ""
}

variable "alb_sg_id" {
  type = string
  description = "Security group ID of ALB"
}

# variable "path_public_key" {
#   type = string
#   description = "Path to import public key"
# }

variable "key_name" {
  type = string
  description = "Name of the key pair"
}
