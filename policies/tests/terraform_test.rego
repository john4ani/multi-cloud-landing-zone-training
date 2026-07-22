package terraform.security_test

import data.terraform.security
import rego.v1

training_tags := {
  "application": "cloud-architecture-training",
  "cost-centre": "training",
  "environment": "training",
  "expires-at": "2026-08-31",
  "managed_by": "terraform",
  "owner": "training",
  "project": "multi-cloud-landing-zone",
}

test_allowed_plan_has_no_denials if {
  plan := {"resource_changes": [{
    "address": "aws_s3_bucket.frontend",
    "type": "aws_s3_bucket",
    "change": {"after": {"tags": {
      "application": "cloud-architecture-training",
      "environment": "training",
      "managed_by": "terraform",
      "owner": "training",
    }}},
  }]}
  denials := security.deny with input as plan
  count(denials) == 0
}

test_allowed_azure_plan_has_no_denials if {
  plan := {"resource_changes": [
    {
      "address": "azurerm_mssql_server.workload",
      "type": "azurerm_mssql_server",
      "change": {"after": {
        "minimum_tls_version": "1.2",
        "public_network_access_enabled": true,
        "tags": training_tags,
      }},
    },
    {
      "address": "azurerm_mssql_virtual_network_rule.container_apps",
      "type": "azurerm_mssql_virtual_network_rule",
      "change": {"after": {"subnet_id": "/subscriptions/example/subnets/container-apps"}},
    },
    {
      "address": "azapi_resource.database",
      "type": "azapi_resource",
      "change": {"after": {
        "type": "Microsoft.Sql/servers/databases@2025-01-01",
        "body": {"properties": {
          "freeLimitExhaustionBehavior": "AutoPause",
          "useFreeLimit": true,
        }},
        "tags": training_tags,
      }},
    },
  ]}
  denials := security.deny with input as plan
  count(denials) == 0
}

test_public_database_is_denied if {
  plan := {"resource_changes": [{
    "address": "aws_db_instance.training",
    "type": "aws_db_instance",
    "change": {"after": {"publicly_accessible": true}},
  }]}
  denials := security.deny with input as plan
  some message in denials
  contains(message, "must not be publicly accessible")
}

test_azure_sql_without_vnet_rule_is_denied if {
  plan := {"resource_changes": [{
    "address": "azurerm_mssql_server.workload",
    "type": "azurerm_mssql_server",
    "change": {"after": {
      "minimum_tls_version": "1.2",
      "public_network_access_enabled": true,
      "tags": training_tags,
    }},
  }]}
  denials := security.deny with input as plan
  some message in denials
  contains(message, "only when a SQL virtual-network rule exists")
}

test_azure_sql_billing_overage_is_denied if {
  plan := {"resource_changes": [{
    "address": "azapi_resource.database",
    "type": "azapi_resource",
    "change": {"after": {
      "type": "Microsoft.Sql/servers/databases@2025-01-01",
      "body": {"properties": {
        "freeLimitExhaustionBehavior": "BillOverUsage",
        "useFreeLimit": true,
      }},
      "tags": training_tags,
    }},
  }]}
  denials := security.deny with input as plan
  some message in denials
  contains(message, "must auto-pause")
}

test_paid_private_endpoint_is_denied if {
  plan := {"resource_changes": [{
    "address": "azurerm_private_endpoint.database",
    "type": "azurerm_private_endpoint",
    "change": {"after": {}},
  }]}
  denials := security.deny with input as plan
  some message in denials
  contains(message, "paid networking component")
}
