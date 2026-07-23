variable "region" {
  type = string
}

variable "resource_prefix" {
  type = string
}

variable "lambda_package_path" {
  type = string
}

variable "database_name" {
  type = string
}

variable "database_admin_username" {
  type = string
}

variable "database_admin_password" {
  type      = string
  sensitive = true
}

variable "database_admin_password_version" {
  type = number
}

variable "database_runtime_username" {
  type = string
  validation {
    condition     = can(regex("^[a-z_][a-z0-9_]{0,62}$", var.database_runtime_username))
    error_message = "database_runtime_username must be a safe unquoted PostgreSQL identifier."
  }
}

variable "database_instance_class" {
  type = string
}

variable "database_allocated_storage" {
  type = number
}

variable "authentication_enabled" {
  type = bool
}

variable "additional_callback_urls" {
  type = list(string)
}

variable "additional_logout_urls" {
  type = list(string)
}

variable "monthly_budget_amount" {
  type = number
}

variable "alert_contact_emails" {
  type = list(string)
}

variable "lambda_reserved_concurrency" {
  type = number
}

variable "log_retention_days" {
  type = number
}

variable "tags" {
  type = map(string)
}
