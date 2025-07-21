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

variable "s3_force_del" {
  type        = bool
  description = "Force destroy the ECR repository"
}