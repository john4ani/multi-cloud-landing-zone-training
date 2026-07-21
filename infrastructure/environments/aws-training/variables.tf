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

variable "database_password" {
  type      = string
  sensitive = true
  default   = null
  nullable  = true
}
