variable "common" {
  type = object({
    region     = string
    account_id = number
    project    = string
    env        = string
  })
}

variable "network" {
  type = object({
    vpc_id             = string
    private_subnet_ids = list(string)
    public_subnet_ids  = list(string)
  })
}

variable "redis_name" {
  type = string
}

variable "redis_port" {
  type = number
}

variable "allowed_sg_ids_access_redis" {
  type = list(string)
}

variable "allowed_cidr_blocks_access_redis" {
  type = list(string)
}

variable "redis_parameters" {
  type        = map(string)
  description = "Custom parameters for Cache instance"
}

variable "redis_engine" {
  type = string
}

variable "redis_family" {
  type = string
}

variable "redis_node_type" {
  type = string
}

variable "redis_num_cache_nodes" {
  type = string
}

variable "redis_engine_version" {
  type = string
}

variable "redis_snapshot_retention_limit" {
  type = number
}

variable "tags" {
  default = {}
}





