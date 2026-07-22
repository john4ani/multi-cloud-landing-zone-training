output "api_fqdn" {
  value = azurerm_container_app.api.latest_revision_fqdn
}

output "api_identity_client_id" {
  value = azurerm_user_assigned_identity.api.client_id
}

output "api_identity_name" {
  value = azurerm_user_assigned_identity.api.name
}

output "api_identity_principal_id" {
  value = azurerm_user_assigned_identity.api.principal_id
}

output "azure_sql_database_name" {
  value = azapi_resource.database.name
}

output "azure_sql_server_fqdn" {
  value = azurerm_mssql_server.workload.fully_qualified_domain_name
}

output "azure_sql_server_name" {
  value = azurerm_mssql_server.workload.name
}

output "frontend_hostname" {
  value = azurerm_static_web_app.frontend.default_host_name
}

output "key_vault_name" {
  value = azurerm_key_vault.workload.name
}

output "resource_group_name" {
  value = azurerm_resource_group.workload.name
}

output "subnet_id" {
  value = azurerm_subnet.container_apps.id
}
