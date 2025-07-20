variable "project" {
  type = object({
    name       = string
    env        = string
    region     = string
    account_id = string
  })
}
variable "tags" {
  type = object({
    Name = string
  })
}

variable "source_services" {
  type = set(string)
}
