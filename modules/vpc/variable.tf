variable "project" {
  type = object({
    env = string
    name = string
    region = string
    account_id = string
  })
}

variable "cidr_block" {
  type = string
}

variable "subnet_az" {
  type = map(number)
}


