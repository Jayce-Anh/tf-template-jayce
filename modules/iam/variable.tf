variable "project" {
  type = object({
    name = string
    env  = string
  })
}

variable "name" {
  type        = string
  description = "The logical name of role"
}

variable "trustrels" {
  type        = any
  description = "The map of trust relationship to allow them to assume roles in this role"
  default     = {}
}

variable "policy_arn" {
  type        = list(string)
  description = "A list of full arn of iam policies to attach this role"
}

variable "session_duration" {
  type        = string
  description = "A value for maximum time of session duration in seconds (default 1h). This setting can have a value from 1 hour to 12 hours"
  default     = "3600"
}

variable "inline_policy" {
  type        = map(string)
  description = "the map of inline policies"
  default     = {}
}

variable "create_instance_profile" {
  type    = bool
  default = false
}

variable "enable_github_action" {
  type    = bool
  default = false
}

variable "github_action_options" {
  type    = any
  default = {}
}
