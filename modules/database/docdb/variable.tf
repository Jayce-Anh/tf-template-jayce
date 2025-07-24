##################################### Variables #####################################

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

variable "network" {
  type = object({
    vpc_id             = string
    private_subnet_ids = list(string)
    public_subnet_ids  = list(string)
  })
}

variable "docdb_name" {
  type = string
}

variable "docdb_family" {
  description = "The DB parameter group family"
  type        = string
}

variable "docdb_engine_version" {
  description = "DocumentDB engine version"
  type        = string
}

variable "docdb_username" {
  description = "Master username for the DocumentDB cluster"
  type        = string
}

variable "docdb_password" {
  description = "Master password for the DocumentDB cluster"
  type        = string
  sensitive   = true
}

variable "docdb_port" {
  description = "Port on which the DocumentDB accepts connections"
  type        = number
}

variable "instance_count" {
  description = "Number of DocumentDB instances to create"
  type        = number
}

variable "instance_class" {
  description = "Instance class for DocumentDB instances"
  type        = string
}

variable "backup_retention_period" {
  description = "The days to retain backups for"
  type        = number
  default     = 7
}

variable "preferred_backup_window" {
  description = "The daily time range during which automated backups are performed"
  type        = string
}

variable "preferred_maintenance_window" {
  description = "The weekly time range during which system maintenance can occur"
  type        = string
}

variable "storage_encrypted" {
  description = "Specifies whether the DocumentDB cluster is encrypted"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "The ARN for the KMS encryption key"
  type        = string
  default     = null
}

variable "skip_final_snapshot" {
  description = "Determines whether a final DocumentDB snapshot is created before the cluster is deleted"
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "A value that indicates whether the DocumentDB cluster has deletion protection enabled"
  type        = bool
  default     = false
}

variable "apply_immediately" {
  description = "Specifies whether any cluster modifications are applied immediately"
  type        = bool
  default     = false
}

variable "enabled_cloudwatch_logs_exports" {
  description = "List of log types to export to CloudWatch"
  type        = list(string)
  default     = ["audit", "profiler"]
}

variable "docdb_parameters" {
  description = "A map of DocumentDB parameters to apply"
  type        = map(string)
  default     = {}
}

variable "ca_cert_identifier" {
  description = "The identifier of the CA certificate for the DB instance"
  type        = string
  default     = "rds-ca-2019"
} 

variable "allowed_sg_ids_access_docdb" {
  description = "List of security group IDs to allow access to the DocumentDB cluster"
  type        = list(string)
  default     = []
}