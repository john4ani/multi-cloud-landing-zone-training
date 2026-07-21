# Implementation status

Last updated: 2026-07-21

## Implemented

- Angular 22 responsive training UI.
- .NET 10 clean-layered API with interview-topic CRUD.
- EF Core repository abstraction with SQL Server and PostgreSQL providers.
- Optional JWT bearer validation for Microsoft Entra ID or Amazon Cognito.
- Local PostgreSQL and SQL Server Compose profiles.
- Separate Azure and AWS Terraform bootstrap and environment roots.
- Safe `deploy_workload = false` defaults.
- Initial Azure frontend, identity, and logging resources.
- Initial AWS private frontend bucket and Cognito resources.
- OPA/Rego security rules with allowed and denied plan fixtures.
- SHA-pinned pull-request validation workflow.

## Next implementation slice

- Create and test provider-specific EF Core migrations.
- Complete Azure Container Apps, private Azure SQL, networking, Entra, budget, and alert resources.
- Complete AWS CloudFront, Lambda, private RDS PostgreSQL, networking, budget, alarm, and destroy resources.
- Add Entra and Cognito Angular login adapters.
- Add OIDC bootstrap for separate plan and apply identities.
- Add protected, exact-plan apply and smoke-test workflows.
- Add cost-estimation and post-destroy inventory evidence.

The diagrams describe the intended target architecture. This status file distinguishes that target from the currently implemented slice.
