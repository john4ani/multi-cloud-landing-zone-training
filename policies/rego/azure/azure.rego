package terraform.security

import rego.v1

azure_cost_tags := {"cost-centre", "expires-at", "project"}

azure_governed_resource_types := {
  "azapi_resource",
  "azurerm_container_app",
  "azurerm_container_app_environment",
  "azurerm_key_vault",
  "azurerm_log_analytics_workspace",
  "azurerm_monitor_action_group",
  "azurerm_monitor_activity_log_alert",
  "azurerm_mssql_server",
  "azurerm_resource_group",
  "azurerm_static_web_app",
  "azurerm_user_assigned_identity",
  "azurerm_virtual_network",
}

has_mssql_vnet_rule if {
  change := input.resource_changes[_]
  change.type == "azurerm_mssql_virtual_network_rule"
  change.change.after.subnet_id != null
}

deny contains message if {
  change := input.resource_changes[_]
  azure_governed_resource_types[change.type]
  after := change.change.after
  missing := azure_cost_tags - object.keys(after.tags)
  count(missing) > 0
  message := sprintf("%s is missing Azure cost-governance tags: %v", [change.address, sort(missing)])
}

deny contains message if {
  change := input.resource_changes[_]
  change.type == "azurerm_storage_account"
  change.change.after.allow_nested_items_to_be_public == true
  message := sprintf("%s permits public nested storage items", [change.address])
}

deny contains message if {
  change := input.resource_changes[_]
  change.type == "azurerm_static_web_app"
  lower(change.change.after.sku_tier) != "free"
  message := sprintf("%s must use the Free training SKU", [change.address])
}

deny contains message if {
  change := input.resource_changes[_]
  change.type == "azurerm_mssql_server"
  change.change.after.minimum_tls_version != "1.2"
  message := sprintf("%s must require TLS 1.2", [change.address])
}

deny contains message if {
  change := input.resource_changes[_]
  change.type == "azurerm_mssql_server"
  change.change.after.public_network_access_enabled == true
  not has_mssql_vnet_rule
  message := sprintf("%s may enable its service endpoint only when a SQL virtual-network rule exists", [change.address])
}

deny contains message if {
  change := input.resource_changes[_]
  change.type == "azurerm_mssql_firewall_rule"
  change.change.after.start_ip_address == "0.0.0.0"
  message := sprintf("%s must not enable the broad Allow Azure services SQL rule", [change.address])
}

deny contains message if {
  change := input.resource_changes[_]
  change.type == "azurerm_mssql_firewall_rule"
  change.change.after.start_ip_address != change.change.after.end_ip_address
  message := sprintf("%s must allow one explicit temporary IP, not an address range", [change.address])
}

deny contains message if {
  change := input.resource_changes[_]
  change.type == "azurerm_subnet"
  contains(change.address, "container_apps")
  not "Microsoft.Sql" in change.change.after.service_endpoints
  message := sprintf("%s must enable the Microsoft.Sql service endpoint", [change.address])
}

deny contains message if {
  change := input.resource_changes[_]
  change.type == "azurerm_key_vault"
  change.change.after.public_network_access_enabled == true
  change.change.after.network_acls[0].default_action != "Deny"
  message := sprintf("%s must default-deny its public service endpoint", [change.address])
}

deny contains message if {
  change := input.resource_changes[_]
  change.type == "azurerm_container_app"
  change.change.after.template[0].min_replicas > 0
  message := sprintf("%s must scale to zero in the training profile", [change.address])
}

deny contains message if {
  change := input.resource_changes[_]
  change.type == "azurerm_container_app"
  change.change.after.template[0].max_replicas > 1
  message := sprintf("%s must cap the training profile at one replica", [change.address])
}

deny contains message if {
  change := input.resource_changes[_]
  change.type == "azapi_resource"
  change.change.after.type == "Microsoft.Sql/servers/databases@2025-01-01"
  change.change.after.body.properties.useFreeLimit != true
  message := sprintf("%s must enable the Azure SQL monthly free limit", [change.address])
}

deny contains message if {
  change := input.resource_changes[_]
  change.type == "azapi_resource"
  change.change.after.type == "Microsoft.Sql/servers/databases@2025-01-01"
  change.change.after.body.properties.freeLimitExhaustionBehavior != "AutoPause"
  message := sprintf("%s must auto-pause instead of billing after free-limit exhaustion", [change.address])
}

deny contains message if {
  change := input.resource_changes[_]
  change.type in {"azurerm_nat_gateway", "azurerm_private_endpoint", "azurerm_firewall"}
  message := sprintf("%s is a paid networking component prohibited in the low-cost training profile", [change.address])
}
