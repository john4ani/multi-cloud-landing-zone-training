# ADR-0010: Host ASP.NET Core on .NET 10 Lambda with IAM-authenticated PostgreSQL

- Status: Accepted and implemented
- Date: 2026-07-23

## Context

The AWS training workload must run the same ASP.NET Core API and PostgreSQL EF Core migrations as local development while keeping idle compute cost, public attack surface, database credentials, and connection pressure low. The VPC intentionally has no NAT Gateway, and the database must remain private.

## Decision

- Host the API on the AWS Lambda managed `dotnet10` runtime behind an API Gateway HTTP API.
- Package the API as a reviewed ZIP. Terraform requires the local package and deploys its SHA-256-derived source hash; artifact creation remains separate from infrastructure planning.
- Use `Amazon.Lambda.AspNetCoreServer.Hosting` to translate API Gateway HTTP API events into the existing ASP.NET Core pipeline without moving business logic into a cloud-specific project.
- Put the API Lambda in two private subnets and cap reserved concurrency at two by default. Do not deploy a NAT Gateway or RDS Proxy.
- Use RDS PostgreSQL IAM database authentication for the runtime user. Npgsql refreshes the short-lived token through its periodic password provider and the Lambda role receives `rds-db:connect` only for the exact database resource and user.
- Use Terraform's write-only RDS `password_wo` for the bootstrap administrator password so it is discarded from plan and state.
- Deploy a second, untriggered migration Lambda from the same ZIP. It receives the administrator password only in an explicit invocation payload, applies the PostgreSQL migration history, provisions the least-privilege IAM database user, and never stores or logs the password.
- Include the current Amazon RDS global CA bundle in the ZIP and require full TLS hostname and certificate validation.
- Keep authentication disabled by default; enable the implemented Angular Cognito adapter and conditional API Gateway/API JWT validation only for an explicit sign-in test deployment.

## Consequences

- Lambda and API Gateway can remain near zero at low request volume, but private RDS consumes Free Plan credits or incurs cost while running.
- Cold starts and VPC attachment add latency; this is acceptable for the training workload.
- The migration function is privileged inside PostgreSQL but has no public event source and a fixed migration-only handler.
- The bootstrap password must exist in a protected operator or CI secret store for deployment and disaster recovery. It is not a runtime application credential.
- The API has no general internet egress. A future external dependency requires a new network/cost decision.
- Schema migration remains an explicit deployment stage rather than an application-startup side effect.

## Validation

- .NET build and tests cover normal local hosting after Lambda hosting is registered.
- Terraform policy rejects public/unencrypted RDS, broad PostgreSQL CIDRs, unapproved instance classes, excess Lambda concurrency, NAT Gateway, RDS Proxy, and non-HTTPS CloudFront behavior.
- A real AWS test invokes the migration function, then verifies API health and CRUD through CloudFront.
- The runtime role is denied database connections under any database username except the configured runtime user.
- Post-destroy inventory contains only the separately managed Terraform-state bootstrap resources.

## References

- [AWS Lambda .NET 10 runtime](https://docs.aws.amazon.com/lambda/latest/dg/lambda-csharp.html)
- [ASP.NET Core Lambda hosting package](https://www.nuget.org/packages/Amazon.Lambda.AspNetCoreServer.Hosting/)
- [IAM database authentication for RDS](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.IAMDBAuth.html)
- [Npgsql periodic password provider](https://www.npgsql.org/doc/security.html#auth-token-rotation-and-dynamic-password)
- [Terraform write-only values](https://developer.hashicorp.com/terraform/language/manage-sensitive-data/write-only)
