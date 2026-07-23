package terraform.security

import rego.v1

required_tags := {"application", "environment", "managed_by", "owner"}

tagged_resource_types := {
  "azapi_resource",
  "azurerm_container_app",
  "azurerm_container_app_environment",
  "azurerm_key_vault",
  "azurerm_resource_group",
  "azurerm_static_web_app",
  "azurerm_user_assigned_identity",
  "azurerm_log_analytics_workspace",
  "azurerm_monitor_action_group",
  "azurerm_monitor_activity_log_alert",
  "azurerm_mssql_server",
  "azurerm_virtual_network",
  "aws_s3_bucket",
  "aws_cognito_user_pool",
  "aws_cloudfront_distribution",
  "aws_cloudwatch_log_group",
  "aws_cloudwatch_metric_alarm",
  "aws_db_instance",
  "aws_db_parameter_group",
  "aws_db_subnet_group",
  "aws_iam_role",
  "aws_lambda_function",
  "aws_sns_topic",
  "aws_subnet",
  "aws_vpc",
}

deny contains message if {
  change := input.resource_changes[_]
  tagged_resource_types[change.type]
  after := change.change.after
  missing := required_tags - object.keys(after.tags)
  count(missing) > 0
  message := sprintf("%s is missing required tags: %v", [change.address, sort(missing)])
}

deny contains message if {
  change := input.resource_changes[_]
  change.type == "aws_db_instance"
  change.change.after.publicly_accessible == true
  message := sprintf("%s must not be publicly accessible", [change.address])
}

deny contains message if {
  change := input.resource_changes[_]
  change.type == "azurerm_container_app"
  container := change.change.after.template[0].container[_]
  endswith(container.image, ":latest")
  message := sprintf("%s uses an unpinned latest container image", [change.address])
}
