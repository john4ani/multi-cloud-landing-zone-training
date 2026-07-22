variable "location" {
  type = string
}

variable "resource_prefix" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "api_container_image" {
  type = string
  validation {
    condition     = can(regex("@sha256:[0-9a-fA-F]{64}$", var.api_container_image))
    error_message = "api_container_image must be immutable and end with @sha256:<64 hex characters>."
  }
}

variable "authentication_enabled" {
  type = bool
}

variable "entra_authority" {
  type = string
}

variable "entra_audience" {
  type = string
}

variable "database_name" {
  type = string
}

variable "sql_admin_login" {
  type = string
}

variable "sql_admin_password" {
  type      = string
  sensitive = true
}

variable "sql_admin_password_version" {
  type = number
}

variable "sql_entra_admin_login" {
  type = string
}

variable "sql_entra_admin_object_id" {
  type     = string
  default  = null
  nullable = true
}

variable "vnet_address_space" {
  type = string
}

variable "container_apps_subnet_prefix" {
  type = string
}

variable "monthly_budget_amount" {
  type = number
}

variable "budget_start_date" {
  type = string
  validation {
    condition     = can(regex("^[0-9]{4}-[0-9]{2}-01T00:00:00Z$", var.budget_start_date))
    error_message = "budget_start_date must be the first day of a month in YYYY-MM-01T00:00:00Z format."
  }
}

variable "alert_contact_emails" {
  type = list(string)
}

variable "log_daily_quota_gb" {
  type = number
}

variable "tags" {
  type = map(string)
}
