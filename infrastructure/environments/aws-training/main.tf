locals {
  tags = {
    application = "cloud-architecture-training"
    environment = "training"
    managed_by  = "terraform"
    owner       = var.owner
  }
}

module "training_platform" {
  count             = var.deploy_workload ? 1 : 0
  source            = "../../modules/aws/training_platform"
  region            = var.region
  resource_prefix   = var.resource_prefix
  database_password = var.database_password
  tags              = local.tags
}
