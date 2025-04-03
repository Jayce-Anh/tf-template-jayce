variable "project" {
  type = object({
    region     = string
    account_id = number
    name       = string
    env        = string
  })
}

variable "tg_name" {
  type = string
}

variable "health_check_path" {
  type = string
}

variable "service_port" {
  type = number
}

variable "vpc_id" {
  type = string
}

variable "lb_listener_arn" {
  description = "The ARN of the ALB listener"
  type = string
}

variable "ec2_id" {
  type = string
}

# variable "container_id" {
#   type = string
# }

variable "priority" {
  type = number
}

variable "host_header" {
  type = string
}

