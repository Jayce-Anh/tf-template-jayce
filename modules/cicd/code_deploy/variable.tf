variable "codedeploy_role_arn" {}
variable "instance_codedeploy" {}

variable "project" {
  type = object({
    region     = string
    name       = string
    env        = string
  })
}

variable "appspec_file" {
  type = string
}

variable "appspec_path" {
  type = string
}

variable "env_vars_codedeploy" {
  type = map(string)
}
