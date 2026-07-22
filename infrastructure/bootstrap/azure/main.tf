data "azurerm_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 8
  upper   = false
  special = false
}

resource "azurerm_resource_group" "state" {
  name     = "rg-cloud-training-tfstate"
  location = var.location
  tags     = var.tags
}

resource "azurerm_resource_group" "workload" {
  name     = var.workload_resource_group_name
  location = var.location
  tags     = merge(var.tags, { environment = "training" })
}

resource "azurerm_storage_account" "state" {
  name                            = "stcloudtraining${random_string.suffix.result}"
  resource_group_name             = azurerm_resource_group.state.name
  location                        = azurerm_resource_group.state.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false
  tags                            = var.tags

  blob_properties {
    versioning_enabled = true
    delete_retention_policy { days = 7 }
    container_delete_retention_policy { days = 7 }
  }
}

resource "azurerm_storage_container" "state" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.state.id
  container_access_type = "private"
}

resource "azurerm_user_assigned_identity" "github_plan" {
  count               = var.configure_github_oidc ? 1 : 0
  name                = "id-cloud-training-github-plan"
  resource_group_name = azurerm_resource_group.state.name
  location            = azurerm_resource_group.state.location
  tags                = var.tags
}

resource "azurerm_user_assigned_identity" "github_apply" {
  count               = var.configure_github_oidc ? 1 : 0
  name                = "id-cloud-training-github-apply"
  resource_group_name = azurerm_resource_group.state.name
  location            = azurerm_resource_group.state.location
  tags                = var.tags
}

locals {
  github_issuer = "https://token.actions.githubusercontent.com"
  plan_subjects = var.configure_github_oidc ? {
    pull_request = "repo:${var.github_repository}:pull_request"
    main         = "repo:${var.github_repository}:ref:refs/heads/main"
    environment  = "repo:${var.github_repository}:environment:azure-training-plan"
  } : {}
}

resource "azurerm_federated_identity_credential" "github_plan" {
  for_each            = local.plan_subjects
  name                = "github-${replace(each.key, "_", "-")}"
  resource_group_name = azurerm_resource_group.state.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = local.github_issuer
  parent_id           = azurerm_user_assigned_identity.github_plan[0].id
  subject             = each.value
}

resource "azurerm_federated_identity_credential" "github_apply" {
  count               = var.configure_github_oidc ? 1 : 0
  name                = "github-azure-training"
  resource_group_name = azurerm_resource_group.state.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = local.github_issuer
  parent_id           = azurerm_user_assigned_identity.github_apply[0].id
  subject             = "repo:${var.github_repository}:environment:azure-training"
}

resource "azurerm_role_assignment" "plan_workload_reader" {
  count                = var.configure_github_oidc ? 1 : 0
  scope                = azurerm_resource_group.workload.id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.github_plan[0].principal_id
}

resource "azurerm_role_assignment" "plan_state_reader" {
  count                = var.configure_github_oidc ? 1 : 0
  scope                = azurerm_storage_account.state.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_user_assigned_identity.github_plan[0].principal_id
}

resource "azurerm_role_assignment" "apply_workload_contributor" {
  count                = var.configure_github_oidc ? 1 : 0
  scope                = azurerm_resource_group.workload.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.github_apply[0].principal_id
}

resource "azurerm_role_assignment" "apply_state_contributor" {
  count                = var.configure_github_oidc ? 1 : 0
  scope                = azurerm_storage_account.state.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.github_apply[0].principal_id
}
