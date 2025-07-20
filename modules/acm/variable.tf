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

variable "region" {
  type = string
}

variable "domain" {
  type = string
}

