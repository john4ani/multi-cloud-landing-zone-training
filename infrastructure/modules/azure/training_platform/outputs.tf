output "frontend_hostname" { value = azurerm_static_web_app.frontend.default_host_name }
output "api_identity_client_id" { value = azurerm_user_assigned_identity.api.client_id }
output "resource_group_name" { value = azurerm_resource_group.workload.name }
