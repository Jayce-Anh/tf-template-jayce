variable "project" {
  type = object({
    name  = string
    env   = string
  })
}

variable "source_services" {
  type = set(string)
}