variable "region" { type = string }
variable "resource_prefix" { type = string }
variable "database_password" {
  type      = string
  sensitive = true
  nullable  = true
}
variable "tags" { type = map(string) }
