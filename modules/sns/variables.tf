variable "project" {
  type = object({
    region     = string
    account_id = number
    project    = string
    env        = string
  })
}

variable "URL_GG_HOOK" {
  type = string
}