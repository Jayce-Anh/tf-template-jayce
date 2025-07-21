variable "git_token" {}
variable "git_org" {}
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

variable "tags" {
  type = object({
    Name = string
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

variable "enable_ecs_deploy" {
  type        = bool
  description = "Enable ECS deployment stage"
  default     = false
}

variable "ecs_cluster_name" {
  type        = string
  description = "Name of the ECS cluster"
  default     = null
}

variable "ecs_service_name" {
  type        = string
  description = "Name of the ECS service"
  default     = null
}

variable "s3_force_del" {
  type        = bool
  description = "Force destroy the S3 bucket"
}

