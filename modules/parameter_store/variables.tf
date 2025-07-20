variable "project" {
  type = object({
    name = string
    env  = string
  })
}

variable "tags" {
  type = object({
    Name = string
  })
}

variable "source_services" {
  description = "List of services to create parameter store"
  type        = list(string)
  default     = []
}

