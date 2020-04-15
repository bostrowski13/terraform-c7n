variable "region" {
  type        = string
  description = "The target AWS region to deploy to"
}

variable "environment" {
  type        = string
  description = "The environment name to deploy to"
}

variable "resource_prefix" {
  type        = string
  description = "Full resource prefix"
}

variable "c7n_reports_root_folder" {
  type        = string
  description = "The root level destination folder in s3 to store c7n reports"
  default     = "reports"
}

variable "c7n_lambda_memory_size" {
  type        = number
  description = "The amount of memory (in MB) to assign to the custodian lambdas managing policy audits"
  default     = 256
}

variable "slack_webhook_endpoint" {
  type        = string
  description = "The slack webhook endpoint for the channel to send notifications to (e.g. https://hooks.slack.com/xxxxxxx)"
}

variable "max_receive_count" {
  type        = number
  description = "The number of times the consumer of the source queue attempts to receive the message"
  default     = 5
}

variable "message_retention_seconds" {
  type        = number
  description = "The number of seconds Amazon SQS retains a message"
  default     = 14400
}

variable "noncurrent_version_transition_days_slow_storage" {
  type        = number
  description = "The number of days before the non current version of an object is transitioned to slower storage"
  default     = 30
}

variable "noncurrent_version_transition_days_archive_storage" {
  type        = number
  description = "The number of days before the non current version of an object is transitioned to archive storage"
  default     = 60
}

variable "noncurrent_version_expiration_days" {
  type        = number
  description = "The number of days before the non current version of an object is deleted from storage completely"
  default     = 90
}

variable "c7n_cw_log_group" {
  type        = string
  description = "The path for cloudwatch logs for custodian policy execution"
  default     = "/cloud-custodian/policies"
}

variable "logging_retention_days" {
  type        = number
  description = "The number of days to keep logs in cloudwatch, and for resources related to managing those"
  default     = 14
}

variable "tags" {
  type        = map
  description = "Tags to attach to the resource"
  default     = {}
}
