variable "lb_sg_id" {
  description = "Load balancer security group id"
  type = string
}

variable "target_group_arn" {}
variable "vpc_id" {}
variable "network_mode" {
  type = string
  default = "awsvpc"
}

variable "subnets" {
  type = list(string)
  description = "Subnets for ECS service"
}

 variable "project" {
  type = object({
    name = string
    env  = string
    region = string
    account_id = number
  })
}

variable "tags" {
  type = object({
    Name = string
  })
}

variable "containerInsights" {
  type = string
  default = "disabled"
}

variable "task_definitions" {
  type  = map(object({
    container_name = string
    container_image = string 
    desired_count = number
    cpu = number
    memory = number
    container_port = number
    host_port = number
    health_check_path = string
    enable_load_balancer = bool
    load_balancer = optional(object({
      target_group_port = number
      container_port  = number
    }))
  }))
}

variable "log_retention" {
  type = number
  default = 14
}
