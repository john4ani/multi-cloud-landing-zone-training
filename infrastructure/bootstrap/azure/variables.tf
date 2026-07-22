variable "location" {
  type    = string
  default = "westeurope"
}

variable "workload_resource_group_name" {
  type    = string
  default = "rg-cloud-training"
}

variable "configure_github_oidc" {
  type        = bool
  default     = false
  description = "Create the GitHub Actions plan/apply identities, federated credentials, and scoped role assignments."
}

variable "github_repository" {
  type        = string
  default     = ""
  description = "GitHub repository in owner/name form. Required when configure_github_oidc is true."

  validation {
    condition     = !var.configure_github_oidc || can(regex("^[^/]+/[^/]+$", var.github_repository))
    error_message = "github_repository must use owner/name form when configure_github_oidc is true."
  }
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
output "state_resource_group_name" { value = azurerm_resource_group.state.name }
output "workload_resource_group_name" { value = azurerm_resource_group.workload.name }
output "tenant_id" { value = data.azurerm_client_config.current.tenant_id }
output "subscription_id" { value = data.azurerm_client_config.current.subscription_id }
output "github_plan_client_id" { value = var.configure_github_oidc ? azurerm_user_assigned_identity.github_plan[0].client_id : null }
output "github_apply_client_id" { value = var.configure_github_oidc ? azurerm_user_assigned_identity.github_apply[0].client_id : null }
output "github_apply_principal_id" { value = var.configure_github_oidc ? azurerm_user_assigned_identity.github_apply[0].principal_id : null }
