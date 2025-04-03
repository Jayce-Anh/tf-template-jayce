variable "secret_name" {
  type = string
}

variable "project" {
  type = object({
    env = string
    name = string
  })
}

