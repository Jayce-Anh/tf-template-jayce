variable "project" {
  type = object({
    region     = string
    account_id = number
    name       = string
    env        = string
  })
}

variable "tags" {
  type = object({
    Name = string
  })
}

variable "env_vars_codebuild" {}
variable "codebuild_role_arn" {}
variable "buildspec_file" {
  type = string
}

variable "build_name" {
  type = string
}

