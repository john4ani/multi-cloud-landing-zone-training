variable "location" { type = string }
variable "resource_prefix" { type = string }
variable "sql_admin_login" { type = string }
variable "sql_admin_password" {
  type      = string
  sensitive = true
  nullable  = true
}
variable "tags" { type = map(string) }
