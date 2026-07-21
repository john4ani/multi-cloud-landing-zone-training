resource "azurerm_resource_group" "workload" {
  name     = "rg-${var.resource_prefix}"
  location = var.location
  tags     = var.tags
}

resource "azurerm_static_web_app" "frontend" {
  name                = "swa-${var.resource_prefix}"
  resource_group_name = azurerm_resource_group.workload.name
  location            = azurerm_resource_group.workload.location
  sku_tier            = "Free"
  sku_size            = "Free"
  tags                = var.tags
}

resource "azurerm_user_assigned_identity" "api" {
  name                = "id-${var.resource_prefix}-api"
  resource_group_name = azurerm_resource_group.workload.name
  location            = azurerm_resource_group.workload.location
  tags                = var.tags
}

resource "azurerm_log_analytics_workspace" "workload" {
  name                = "log-${var.resource_prefix}"
  resource_group_name = azurerm_resource_group.workload.name
  location            = azurerm_resource_group.workload.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
  daily_quota_gb      = 0.1
  tags                = var.tags
}

# Container Apps, Azure SQL, private networking, and Entra application objects
# are added in the next implementation slice. Their interfaces are reserved by
# the module inputs so they can be introduced without changing environment roots.
