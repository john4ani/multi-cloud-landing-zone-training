variable "deploy_workload" {
  type    = bool
  default = false
}

variable "location" {
  type    = string
  default = "westeurope"
}

variable "resource_prefix" {
  type    = string
  default = "cloud-training"
}

variable "owner" {
  type    = string
  default = "training"
}

variable "cost_centre" {
  type    = string
  default = "training"
}

variable "expires_at" {
  type        = string
  default     = null
  nullable    = true
  description = "Planned destruction or review date in YYYY-MM-DD format. Required for deployment."
}

variable "api_container_image" {
  type        = string
  default     = null
  nullable    = true
  description = "Immutable API image reference ending in @sha256:<digest>. Required for deployment."
}

variable "authentication_enabled" {
  type        = bool
  default     = false
  description = "Enable Entra JWT validation after the application registration slice is configured."
}

variable "entra_authority" {
  type        = string
  default     = ""
  description = "Exact Microsoft Entra issuer/authority URI."
}

variable "entra_audience" {
  type        = string
  default     = "cloud-training-api"
  description = "Expected API access-token audience."
}

variable "database_name" {
  type    = string
  default = "cloud_training"
}

variable "sql_admin_login" {
  type    = string
  default = "cloudadmin"
}

variable "sql_admin_password" {
  type        = string
  sensitive   = true
  default     = null
  nullable    = true
  description = "Bootstrap-only SQL administrator password. Supply with TF_VAR_sql_admin_password."
}

variable "sql_admin_password_version" {
  type        = number
  default     = 1
  description = "Increment to rotate the write-only SQL administrator password."
}

variable "vnet_address_space" {
  type    = string
  default = "10.20.0.0/16"
}

variable "container_apps_subnet_prefix" {
  type    = string
  default = "10.20.0.0/27"
}

variable "monthly_budget_amount" {
  type        = number
  default     = 5
  description = "Resource-group budget in the subscription billing currency."
}

variable "budget_start_date" {
  type        = string
  default     = null
  nullable    = true
  description = "First day of the current month in YYYY-MM-01T00:00:00Z format. Required for deployment."
}

variable "alert_contact_emails" {
  type        = list(string)
  default     = []
  description = "Optional alert recipients. Subscription Owners also receive budget notifications."
}

variable "log_daily_quota_gb" {
  type        = number
  default     = 0.1
  description = "Log Analytics daily ingestion cap in GB."
}
