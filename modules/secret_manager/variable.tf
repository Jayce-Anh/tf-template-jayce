############################### SECRET MANAGER - VARIABLE ###############################

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

variable "secret_name" {
  type        = string
  description = "Name of the secret-manager"
}

variable "recovery_window_in_days" {
  type        = number
  description = "Number of days AWS waits before deleting the secret"
  default     = 30
}
