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

variable "sql_admin_login" {
  type    = string
  default = "cloudadmin"
}

variable "sql_admin_password" {
  type      = string
  sensitive = true
  default   = null
  nullable  = true
}
