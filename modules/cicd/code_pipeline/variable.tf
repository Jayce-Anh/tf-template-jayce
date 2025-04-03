variable "oauth_token" {}
variable "organization" {}
variable "git_repo" {}
variable "git_branch" {}
variable "pipeline_name" {}

variable "project" {
  type = object({
    region     = string
    account_id = number
    name       = string
    env        = string
  })
}

variable "project_name" {
  description = "The name of the code build project"
  type = string
}

# variable "application_name" {
#   description = "The name of the code deploy application"
#   type = string
# }

# variable "deployment_group_name" {
#   description = "The name of the code deploy deployment group"
#   type = string
# }
