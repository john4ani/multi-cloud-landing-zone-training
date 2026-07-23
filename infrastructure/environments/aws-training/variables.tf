variable "deploy_workload" {
  type    = bool
  default = false
}

variable "region" {
  type    = string
  default = "eu-central-1"
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

variable "lambda_package_path" {
  type        = string
  default     = null
  nullable    = true
  description = "Absolute or root-relative path to the reviewed .NET Lambda ZIP. Required for deployment."
}

variable "database_name" {
  type    = string
  default = "cloud_training"
}

variable "database_admin_username" {
  type    = string
  default = "cloudadmin"
}

variable "database_admin_password" {
  type        = string
  sensitive   = true
  default     = null
  nullable    = true
  description = "Bootstrap-only RDS administrator password. Supply through TF_VAR_database_admin_password."
}

variable "database_admin_password_version" {
  type        = number
  default     = 1
  description = "Increment to rotate the write-only RDS administrator password."
}

variable "database_runtime_username" {
  type    = string
  default = "cloud_app"
}

variable "database_instance_class" {
  type        = string
  default     = "db.t4g.micro"
  description = "Smallest approved Graviton RDS class for the training profile."
}

variable "database_allocated_storage" {
  type        = number
  default     = 20
  description = "Fixed gp3 storage in GiB. Autoscaling is disabled to bound cost."
}

variable "authentication_enabled" {
  type        = bool
  default     = false
  description = "Enable Cognito JWT enforcement after the Angular login adapter is configured."
}

variable "additional_callback_urls" {
  type        = list(string)
  default     = ["http://localhost:4200/authentication/callback"]
  description = "Additional exact Cognito callback URLs for local development."
}

variable "additional_logout_urls" {
  type        = list(string)
  default     = ["http://localhost:4200"]
  description = "Additional exact Cognito logout URLs for local development."
}

variable "monthly_budget_amount" {
  type        = number
  default     = 5
  description = "Monthly budget in USD; it alerts but is not a hard cap."
}

variable "alert_contact_emails" {
  type        = list(string)
  default     = []
  description = "Optional AWS Budget and CloudWatch alert recipients. SNS confirmation is required."
}

variable "lambda_reserved_concurrency" {
  type        = number
  default     = 2
  description = "Bounds API scale and PostgreSQL connection pressure."
}

variable "log_retention_days" {
  type        = number
  default     = 7
  description = "Short CloudWatch retention for the disposable training environment."
}
