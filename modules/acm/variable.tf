variable "project" {
  type = object({
    env = string
    name = string
  })
}

variable "domain" {
  type = string
}

