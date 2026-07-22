# Azure training platform module

This module implements the deployable Azure workload slice:

- Angular hosting on Azure Static Web Apps Free.
- ASP.NET Core API on Azure Container Apps Consumption with scale-to-zero.
- A VNet-integrated Container Apps environment and a `Microsoft.Sql` service endpoint.
- Azure SQL Database with the monthly free limit enabled and `AutoPause` on exhaustion.
- User-assigned managed identity for passwordless runtime database access.
- A restricted, RBAC-enabled Key Vault extension point for future secrets.
- Log Analytics with a 0.1 GB daily cap, an activity alert, an action group, and a resource-group budget.

Azure SQL keeps its public service endpoint enabled because service endpoints operate on that endpoint. Access is selected-network only: the module creates no permanent IP firewall rule and authorizes only the Container Apps subnet through an SQL virtual-network rule. Private Link, NAT Gateway, and Azure Firewall are deliberately excluded from the low-cost profile.

The AzureRM provider does not currently expose the free database controls, so the database alone is managed through AzAPI using the stable `Microsoft.Sql/servers/databases@2025-01-01` API. All other resources use AzureRM.

Deployment remains opt-in at the environment root. A free-tier label does not guarantee a zero invoice; confirm subscription eligibility, region support, current prices, and the Terraform plan before applying.
