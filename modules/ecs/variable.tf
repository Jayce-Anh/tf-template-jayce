variable "common" {
  type = object({
    project = string
    env     = string
  })
}

variable "vpc_id" {
  type = string
}
