variable "project" {
  type = object({
    region     = string
    account_id = number
    name       = string
    env        = string
  })
}

variable "env_vars_codebuild" {}
variable "codebuild_role_arn" {}
variable "buildspec_file" {
  type = string
}

