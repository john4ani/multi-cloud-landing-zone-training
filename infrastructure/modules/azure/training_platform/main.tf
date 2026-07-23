data "azurerm_client_config" "current" {}

locals {
  unique_suffix   = substr(sha1("${data.azurerm_client_config.current.subscription_id}-${var.resource_prefix}"), 0, 7)
  sql_server_name = substr("sql-${var.resource_prefix}-${local.unique_suffix}", 0, 63)
  key_vault_name  = substr("kv-${replace(var.resource_prefix, "-", "")}-${local.unique_suffix}", 0, 24)
  frontend_origin = "https://${azurerm_static_web_app.frontend.default_host_name}"
}

data "azurerm_resource_group" "workload" {
  name = var.resource_group_name
}

resource "azurerm_virtual_network" "workload" {
  name                = "vnet-${var.resource_prefix}"
  resource_group_name = data.azurerm_resource_group.workload.name
  location            = data.azurerm_resource_group.workload.location
  address_space       = [var.vnet_address_space]
  tags                = var.tags
}

resource "azurerm_subnet" "container_apps" {
  name                 = "snet-container-apps"
  resource_group_name  = data.azurerm_resource_group.workload.name
  virtual_network_name = azurerm_virtual_network.workload.name
  address_prefixes     = [var.container_apps_subnet_prefix]
  service_endpoints    = ["Microsoft.KeyVault", "Microsoft.Sql"]

  delegation {
    name = "container-apps-environment"
    service_delegation {
      name    = "Microsoft.App/environments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_static_web_app" "frontend" {
  name                = "swa-${var.resource_prefix}"
  resource_group_name = data.azurerm_resource_group.workload.name
  location            = data.azurerm_resource_group.workload.location
  sku_tier            = "Free"
  sku_size            = "Free"
  tags                = var.tags
}

resource "azurerm_user_assigned_identity" "api" {
  name                = "id-${var.resource_prefix}-api"
  resource_group_name = data.azurerm_resource_group.workload.name
  location            = data.azurerm_resource_group.workload.location
  tags                = var.tags
}

resource "azurerm_log_analytics_workspace" "workload" {
  name                = "log-${var.resource_prefix}"
  resource_group_name = data.azurerm_resource_group.workload.name
  location            = data.azurerm_resource_group.workload.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
  daily_quota_gb      = var.log_daily_quota_gb
  tags                = var.tags
}

resource "azurerm_container_app_environment" "workload" {
  name                           = "cae-${var.resource_prefix}"
  resource_group_name            = data.azurerm_resource_group.workload.name
  location                       = data.azurerm_resource_group.workload.location
  infrastructure_subnet_id       = azurerm_subnet.container_apps.id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.workload.id
  logs_destination               = "log-analytics"
  internal_load_balancer_enabled = false
  public_network_access          = "Enabled"
  zone_redundancy_enabled        = false
  tags                           = var.tags

  workload_profile {
    name                  = "Consumption"
    workload_profile_type = "Consumption"
    minimum_count         = 0
    maximum_count         = 0
  }
}

resource "azurerm_mssql_server" "workload" {
  name                                    = local.sql_server_name
  resource_group_name                     = data.azurerm_resource_group.workload.name
  location                                = data.azurerm_resource_group.workload.location
  version                                 = "12.0"
  administrator_login                     = var.sql_admin_login
  administrator_login_password_wo         = var.sql_admin_password
  administrator_login_password_wo_version = var.sql_admin_password_version
  minimum_tls_version                     = "1.2"
  public_network_access_enabled           = true
  outbound_network_restriction_enabled    = true
  tags                                    = var.tags

  azuread_administrator {
    login_username              = var.sql_entra_admin_login
    object_id                   = coalesce(var.sql_entra_admin_object_id, data.azurerm_client_config.current.object_id)
    tenant_id                   = data.azurerm_client_config.current.tenant_id
    azuread_authentication_only = false
  }
}

resource "azurerm_mssql_virtual_network_rule" "container_apps" {
  name                                 = "allow-container-apps-subnet"
  server_id                            = azurerm_mssql_server.workload.id
  subnet_id                            = azurerm_subnet.container_apps.id
  ignore_missing_vnet_service_endpoint = false
}

# AzureRM 4.81 does not expose Azure SQL's free-limit controls. AzAPI is used
# narrowly so exhaustion auto-pauses the database instead of billing overage.
resource "azapi_resource" "database" {
  type      = "Microsoft.Sql/servers/databases@2025-01-01"
  parent_id = azurerm_mssql_server.workload.id
  name      = var.database_name
  location  = data.azurerm_resource_group.workload.location
  tags      = var.tags

  body = {
    sku = {
      name     = "GP_S_Gen5_1"
      tier     = "GeneralPurpose"
      family   = "Gen5"
      capacity = 1
    }
    properties = {
      autoPauseDelay                   = 60
      freeLimitExhaustionBehavior      = "AutoPause"
      maxSizeBytes                     = 34359738368
      minCapacity                      = 0.5
      requestedBackupStorageRedundancy = "Local"
      useFreeLimit                     = true
      zoneRedundant                    = false
    }
  }

  response_export_values    = ["properties.status"]
  schema_validation_enabled = true
}

resource "azurerm_key_vault" "workload" {
  name                          = local.key_vault_name
  resource_group_name           = data.azurerm_resource_group.workload.name
  location                      = data.azurerm_resource_group.workload.location
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  rbac_authorization_enabled    = true
  public_network_access_enabled = true
  purge_protection_enabled      = false
  soft_delete_retention_days    = 7
  tags                          = var.tags

  network_acls {
    bypass                     = "AzureServices"
    default_action             = "Deny"
    virtual_network_subnet_ids = [azurerm_subnet.container_apps.id]
  }
}

resource "azurerm_container_app" "api" {
  name                         = "ca-${var.resource_prefix}-api"
  resource_group_name          = data.azurerm_resource_group.workload.name
  container_app_environment_id = azurerm_container_app_environment.workload.id
  revision_mode                = "Single"
  max_inactive_revisions       = 1
  tags                         = var.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.api.id]
  }

  ingress {
    external_enabled           = true
    allow_insecure_connections = false
    target_port                = 8080
    transport                  = "auto"

    cors {
      allowed_origins    = [local.frontend_origin]
      allowed_methods    = ["DELETE", "GET", "OPTIONS", "POST", "PUT"]
      allowed_headers    = ["Authorization", "Content-Type"]
      max_age_in_seconds = 3600
    }

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  template {
    min_replicas = 0
    max_replicas = 1

    container {
      name   = "api"
      image  = var.api_container_image
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name  = "ASPNETCORE_ENVIRONMENT"
        value = "Production"
      }
      env {
        name  = "ASPNETCORE_URLS"
        value = "http://+:8080"
      }
      env {
        name  = "Authentication__Enabled"
        value = tostring(var.authentication_enabled)
      }
      env {
        name  = "Authentication__Provider"
        value = "Entra"
      }
      env {
        name  = "Authentication__Authority"
        value = var.entra_authority
      }
      env {
        name  = "Authentication__Audience"
        value = var.entra_audience
      }
      env {
        name  = "Authentication__RoleClaimType"
        value = "roles"
      }
      env {
        name  = "Cors__AllowedOrigins__0"
        value = local.frontend_origin
      }
      env {
        name  = "Database__Provider"
        value = "SqlServer"
      }
      env {
        name  = "ConnectionStrings__TrainingDatabase"
        value = "Server=tcp:${azurerm_mssql_server.workload.fully_qualified_domain_name},1433;Initial Catalog=${azapi_resource.database.name};Authentication=Active Directory Managed Identity;User Id=${azurerm_user_assigned_identity.api.client_id};Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
      }

      liveness_probe {
        transport               = "HTTP"
        port                    = 8080
        path                    = "/health"
        initial_delay           = 15
        interval_seconds        = 30
        timeout                 = 5
        failure_count_threshold = 3
      }

      readiness_probe {
        transport               = "HTTP"
        port                    = 8080
        path                    = "/health"
        interval_seconds        = 10
        timeout                 = 5
        failure_count_threshold = 6
      }
    }
  }

  depends_on = [azurerm_mssql_virtual_network_rule.container_apps]
}

resource "azurerm_monitor_action_group" "training" {
  name                = "ag-${var.resource_prefix}"
  resource_group_name = data.azurerm_resource_group.workload.name
  short_name          = "training"
  tags                = var.tags

  dynamic "email_receiver" {
    for_each = { for index, email in var.alert_contact_emails : tostring(index) => email }
    content {
      name                    = "contact-${email_receiver.key}"
      email_address           = email_receiver.value
      use_common_alert_schema = true
    }
  }
}

resource "azurerm_monitor_activity_log_alert" "resource_group_delete" {
  name                = "alert-${var.resource_prefix}-resource-group-delete"
  resource_group_name = data.azurerm_resource_group.workload.name
  location            = "Global"
  scopes              = [data.azurerm_resource_group.workload.id]
  description         = "Alerts when deletion of the training resource group starts."
  enabled             = true
  tags                = var.tags

  criteria {
    category       = "Administrative"
    operation_name = "Microsoft.Resources/subscriptions/resourceGroups/delete"
    status         = "Started"
  }

  action {
    action_group_id = azurerm_monitor_action_group.training.id
  }
}

resource "azurerm_consumption_budget_resource_group" "training" {
  name              = "budget-${var.resource_prefix}"
  resource_group_id = data.azurerm_resource_group.workload.id
  amount            = var.monthly_budget_amount
  time_grain        = "Monthly"

  time_period {
    start_date = var.budget_start_date
  }

  notification {
    enabled        = true
    operator       = "GreaterThan"
    threshold      = 20
    threshold_type = "Actual"
    contact_groups = [azurerm_monitor_action_group.training.id]
    contact_roles  = ["Owner"]
  }

  notification {
    enabled        = true
    operator       = "GreaterThan"
    threshold      = 100
    threshold_type = "Forecasted"
    contact_groups = [azurerm_monitor_action_group.training.id]
    contact_roles  = ["Owner"]
  }
}
