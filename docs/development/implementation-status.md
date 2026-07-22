# Implementation status

Last updated: 2026-07-22

## Implemented

- Angular 22 responsive training UI.
- .NET 10 clean-layered API with interview-topic CRUD.
- EF Core repository abstraction with SQL Server and PostgreSQL providers.
- Independent, tested PostgreSQL and SQL Server EF Core migration histories.
- Explicit local migration and dual-provider migration-generation scripts.
- Optional JWT bearer validation for Microsoft Entra ID or Amazon Cognito.
- Local PostgreSQL and SQL Server Compose profiles.
- Separate Azure and AWS Terraform bootstrap and environment roots.
- Safe `deploy_workload = false` defaults.
- Azure Static Web Apps, Container Apps Consumption, VNet service endpoints, Azure SQL free-limit controls, managed identity, restricted Key Vault, logging, budget, and alert Terraform resources.
- Azure controlled migration/runtime-identity bootstrap script with temporary firewall cleanup.
- Cross-platform .NET Azure SQL deployment tool; no `sqlcmd` dependency on the runner.
- Azure GitHub Actions validation, speculative plan, protected exact-plan deploy, migration, frontend deployment, CRUD smoke test, token rotation, and guarded destroy workflows.
- Separate Azure plan/apply managed identities with repository/environment-bound OIDC federation and resource-group/state-scoped permissions.
- Runtime Angular configuration for the deployed Azure API endpoint.
- Initial AWS private frontend bucket and Cognito resources.
- OPA/Rego security rules with Azure networking, free-limit, cost, identity, tagging, and allowed/denied plan coverage.
- SHA-pinned pull-request validation workflow.

## Validation boundary

- Azure Terraform syntax, provider schemas, formatting, and OPA rules are validated locally and in CI.
- A real Azure plan/apply, migration, browser smoke test, and cost evidence require the user's Azure subscription, completed bootstrap/GitHub setup, public GHCR package, and explicit protected-environment approval.
- Entra application registrations and Angular login integration are not yet implemented; Azure authentication remains disabled by default.

## Next implementation slice

- Complete the equivalent AWS workload: CloudFront, API Gateway/Lambda, private RDS PostgreSQL, VPC controls, budgets, alarms, migration execution, and destroy evidence.
- Then add Entra and Cognito Angular login adapters.
- Add cost-estimation and post-destroy inventory evidence.

The diagrams describe the intended target architecture. This status file distinguishes deployed evidence from locally validated implementation.
