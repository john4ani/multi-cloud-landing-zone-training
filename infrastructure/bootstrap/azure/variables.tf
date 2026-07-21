variable "location" {
  type    = string
  default = "westeurope"
}

variable "tags" {
  type = map(string)
  default = {
    application = "cloud-architecture-training"
    environment = "bootstrap"
    managed_by  = "terraform"
    owner       = "training"
  }
}

output "storage_account_name" { value = azurerm_storage_account.state.name }
output "container_name" { value = azurerm_storage_container.state.name }
