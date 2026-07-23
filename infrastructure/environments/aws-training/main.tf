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
      condition     = try(var.lambda_package_path != null && fileexists(var.lambda_package_path), false)
      error_message = "Build the reviewed Lambda ZIP and set lambda_package_path before enabling deployment."
    }
    precondition {
      condition     = var.database_admin_password != null && length(var.database_admin_password) >= 16
      error_message = "Set a strong database_admin_password of at least 16 characters through TF_VAR_database_admin_password."
    }
    precondition {
      condition     = var.expires_at != null && can(regex("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", var.expires_at))
      error_message = "Set expires_at to the planned destruction or review date in YYYY-MM-DD format."
    }
    precondition {
      condition     = contains(["db.t4g.micro", "db.t3.micro"], var.database_instance_class)
      error_message = "The training profile permits only db.t4g.micro or db.t3.micro."
    }
    precondition {
      condition     = var.database_allocated_storage == 20
      error_message = "The training profile fixes RDS storage at 20 GiB with autoscaling disabled."
    }
    precondition {
      condition     = var.lambda_reserved_concurrency >= 1 && var.lambda_reserved_concurrency <= 5
      error_message = "Keep Lambda reserved concurrency between 1 and 5 for this database-backed training workload."
    }
  }
}

module "training_platform" {
  count  = var.deploy_workload ? 1 : 0
  source = "../../modules/aws/training_platform"

  region                          = var.region
  resource_prefix                 = var.resource_prefix
  lambda_package_path             = coalesce(var.lambda_package_path, "deployment-disabled.zip")
  database_name                   = var.database_name
  database_admin_username         = var.database_admin_username
  database_admin_password         = coalesce(var.database_admin_password, "deployment-disabled")
  database_admin_password_version = var.database_admin_password_version
  database_runtime_username       = var.database_runtime_username
  database_instance_class         = var.database_instance_class
  database_allocated_storage      = var.database_allocated_storage
  authentication_enabled          = var.authentication_enabled
  additional_callback_urls        = var.additional_callback_urls
  additional_logout_urls          = var.additional_logout_urls
  monthly_budget_amount           = var.monthly_budget_amount
  alert_contact_emails            = var.alert_contact_emails
  lambda_reserved_concurrency     = var.lambda_reserved_concurrency
  log_retention_days              = var.log_retention_days
  tags                            = local.tags

  depends_on = [terraform_data.deployment_guard]
}

output "deployment" {
  value = var.deploy_workload ? {
    api_base_url               = "${module.training_platform[0].frontend_url}/api"
    authentication_authority   = module.training_platform[0].authentication_authority
    authentication_enabled     = module.training_platform[0].authentication_enabled
    authentication_provider    = "Cognito"
    authentication_scope       = module.training_platform[0].authentication_scope
    api_function_name          = module.training_platform[0].api_function_name
    api_gateway_endpoint       = module.training_platform[0].api_gateway_endpoint
    cloudfront_distribution_id = module.training_platform[0].cloudfront_distribution_id
    database_address           = module.training_platform[0].database_address
    database_name              = module.training_platform[0].database_name
    database_port              = module.training_platform[0].database_port
    database_runtime_username  = module.training_platform[0].database_runtime_username
    frontend_bucket_name       = module.training_platform[0].frontend_bucket_name
    frontend_hostname          = module.training_platform[0].frontend_hostname
    frontend_url               = module.training_platform[0].frontend_url
    migration_function_name    = module.training_platform[0].migration_function_name
    user_pool_client_id        = module.training_platform[0].user_pool_client_id
    user_pool_domain           = module.training_platform[0].user_pool_domain
    user_pool_id               = module.training_platform[0].user_pool_id
    vpc_id                     = module.training_platform[0].vpc_id
  } : null
}
