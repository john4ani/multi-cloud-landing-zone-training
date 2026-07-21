locals {
  tags = {
    application = "cloud-architecture-training"
    environment = "training"
    managed_by  = "terraform"
    owner       = var.owner
  }
}

module "training_platform" {
  count              = var.deploy_workload ? 1 : 0
  source             = "../../modules/azure/training_platform"
  location           = var.location
  resource_prefix    = var.resource_prefix
  sql_admin_login    = var.sql_admin_login
  sql_admin_password = var.sql_admin_password
  tags               = local.tags
}
