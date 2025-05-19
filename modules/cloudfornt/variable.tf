variable "project" {
  type = object({
    name = string
    env  = string
  })
}

variable "service_name" {
  type = string
}

# variable "bucket_acl" {
#   type        = string
#   description = "The canned ACL to apply to the bucket"
# }

variable "versioning" {
  description = "Map containing versioning configuration."
  type        = any
  default     = {}
}

variable "ownership_config" {
  description = "Map containing bucket ownership configuration."
  type        = any
  default     = null
}

variable "custom_error_response" {
  description = "One or more custom error response elements"
  type        = any
  default     = {}
}

variable "cf_cert_arn" {
  type = string
}

variable "cloudfront_domain" {
  type = string
}

variable "create_full_access_policy" {
  type        = bool
  description = "whether or not to create iam policy of s3 full access"
  default     = true
}