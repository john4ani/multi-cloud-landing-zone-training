locals {
  tags = {
    application = "cloud-architecture-training"
    project     = "multi-cloud-landing-zone"
    environment = "training"
    managed_by  = "terraform"
    managed-by  = "terraform"
    owner       = var.owner
    cost-centre = var.cost_centre
    expires-at  = coalesce(var.expires_at, "not-deployed")
  }
}

resource "terraform_data" "deployment_guard" {
  count = var.deploy_workload ? 1 : 0

  lifecycle {
    precondition {
      condition     = var.api_container_image != null && can(regex("@sha256:[0-9a-fA-F]{64}$", var.api_container_image))
      error_message = "Set api_container_image to an immutable image digest before enabling deployment."
    }
    precondition {
      condition     = var.sql_admin_password != null && length(var.sql_admin_password) >= 16
      error_message = "Set a strong sql_admin_password of at least 16 characters through TF_VAR_sql_admin_password."
    }
    precondition {
      condition     = var.budget_start_date != null && can(regex("^[0-9]{4}-[0-9]{2}-01T00:00:00Z$", var.budget_start_date))
      error_message = "Set budget_start_date to the first day of the current month in YYYY-MM-01T00:00:00Z format."
    }
    precondition {
      condition     = var.expires_at != null && can(regex("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", var.expires_at))
      error_message = "Set expires_at to the planned destruction or review date in YYYY-MM-DD format."
    }
    precondition {
      condition     = !var.authentication_enabled || (var.entra_authority != "" && var.entra_audience != "")
      error_message = "Set entra_authority and entra_audience when authentication_enabled is true."
    }
  }
}

module "training_platform" {
  count  = var.deploy_workload ? 1 : 0
  source = "../../modules/azure/training_platform"

  location                     = var.location
  resource_prefix              = var.resource_prefix
  api_container_image          = coalesce(var.api_container_image, "invalid.example/api@sha256:0000000000000000000000000000000000000000000000000000000000000000")
  authentication_enabled       = var.authentication_enabled
  entra_authority              = var.entra_authority
  entra_audience               = var.entra_audience
  database_name                = var.database_name
  sql_admin_login              = var.sql_admin_login
  sql_admin_password           = coalesce(var.sql_admin_password, "deployment-disabled")
  sql_admin_password_version   = var.sql_admin_password_version
  vnet_address_space           = var.vnet_address_space
  container_apps_subnet_prefix = var.container_apps_subnet_prefix
  monthly_budget_amount        = var.monthly_budget_amount
  budget_start_date            = coalesce(var.budget_start_date, "2000-01-01T00:00:00Z")
  alert_contact_emails         = var.alert_contact_emails
  log_daily_quota_gb           = var.log_daily_quota_gb
  tags                         = local.tags

  depends_on = [terraform_data.deployment_guard]
}

output "deployment" {
  value = var.deploy_workload ? {
    api_fqdn                  = module.training_platform[0].api_fqdn
    api_identity_name         = module.training_platform[0].api_identity_name
    api_identity_principal_id = module.training_platform[0].api_identity_principal_id
    database_name             = module.training_platform[0].azure_sql_database_name
    frontend_hostname         = module.training_platform[0].frontend_hostname
    resource_group_name       = module.training_platform[0].resource_group_name
    sql_server_fqdn           = module.training_platform[0].azure_sql_server_fqdn
    sql_server_name           = module.training_platform[0].azure_sql_server_name
  } : null
}
