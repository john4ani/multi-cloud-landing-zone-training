# Non-functional requirements

- Status: Accepted baseline
- Accepted: 2026-07-21
- Applies to: Local, Azure training, and AWS training environments

## Purpose and interpretation

These requirements define measurable quality attributes for the interview preparation tracker and its workload-focused landing zones. This is a training system, not a production service. Targets are service objectives for validation and learning; they are not contractual service-level agreements.

## Workload assumptions

| Attribute | Accepted value |
|---|---|
| Users | One initial authenticated user; design supports future multi-user use |
| Roles | `User` and `Administrator` |
| Data | Synthetic interview topics, questions, notes, and progress only |
| Concurrent users | Fewer than 10 |
| Daily API volume | Fewer than 1,000 requests |
| Environments | Local, Azure training, AWS training |
| Azure region | West Europe |
| AWS region | Europe (Ireland), `eu-west-1` |
| Browsers | Current stable Chrome, Edge, Firefox, and Safari |
| Production use | Explicitly prohibited |

## Security and privacy

| ID | Requirement | Verification |
|---|---|---|
| NFR-SEC-001 | All business API endpoints require a valid access token. Only health and authentication bootstrap endpoints may be anonymous. | Integration tests call protected endpoints without, with invalid, and with valid tokens. |
| NFR-SEC-002 | Azure uses Microsoft Entra ID and AWS uses Amazon Cognito. Browser authentication uses Authorization Code with PKCE. | Configuration review and an end-to-end sign-in test on each cloud. |
| NFR-SEC-003 | Authorization distinguishes `User` and `Administrator`. Every data access operation enforces the authenticated owner or an explicit administrator policy. | Authorization and cross-user access tests. |
| NFR-SEC-004 | Cloud administration requires MFA. Workload and pipeline identities use short-lived credentials; long-lived cloud access keys are prohibited. | Identity configuration review and secret scan. |
| NFR-SEC-005 | External traffic uses HTTPS with TLS 1.2 or newer. Database connections require encrypted transport. | TLS configuration check and connection-string policy test. |
| NFR-SEC-006 | Databases are never directly accessible from a browser. AWS PostgreSQL remains private. Azure SQL uses the narrowest practical firewall scope for the training profile, with the residual public-endpoint risk documented. | Network test, Terraform plan policy, and threat-model review. |
| NFR-SEC-007 | Secrets do not appear in source code, committed configuration, Terraform outputs, application logs, container layers, or build artifacts. | Repository, image, log, and Terraform-plan scans. |
| NFR-SEC-008 | Data is encrypted at rest using provider-managed encryption. Customer-managed keys are an optional enterprise extension. | Terraform plan and provider configuration review. |
| NFR-SEC-009 | Only synthetic data is permitted. Real personal, financial, health, customer, employer-confidential, or regulated data is prohibited. | Seed-data review and documentation check. |
| NFR-SEC-010 | Application inputs are validated; database access uses parameterized Entity Framework Core queries; errors do not disclose internal details. | Unit, integration, and dynamic security tests. |
| NFR-SEC-011 | Browser security includes restrictive CORS, Content Security Policy, anti-clickjacking controls, secure content-type handling, and no access-token persistence in local storage. | Browser header test and client code review. |
| NFR-SEC-012 | Dependencies, containers, Terraform, and committed secrets are scanned before deployment. Critical known vulnerabilities block deployment unless a documented, expiring exception exists. | CI security jobs and exception-policy tests. |

## Reliability and recoverability

| ID | Requirement | Verification |
|---|---|---|
| NFR-REL-001 | Availability is best effort. Temporary outages and cold starts are acceptable. | Documented operational expectation. |
| NFR-REL-002 | Infrastructure and application services can be recreated from source control within 60 minutes, excluding provider outages and account provisioning. | Timed clean-environment deployment exercise. |
| NFR-REL-003 | Recovery point objective is 24 hours. Complete loss of synthetic training data is acceptable when seed data can recreate a usable environment. | Restore or reseed exercise. |
| NFR-REL-004 | Seed data and database migrations are repeatable and idempotent. | Repeated integration deployment test. |
| NFR-REL-005 | The API exposes `/health/live` and `/health/ready`; readiness includes required dependency checks without exposing secrets. | Automated smoke tests. |
| NFR-REL-006 | AWS RDS may be single-AZ and Azure services may use free-tier redundancy only. Multi-region and zone-redundant designs remain documented extensions. | Terraform and architecture review. |

## Performance and capacity

| ID | Requirement | Verification |
|---|---|---|
| NFR-PERF-001 | Key pages become usable within 3 seconds at the 95th percentile on a normal broadband connection after initial deployment warm-up. | Browser performance test. |
| NFR-PERF-002 | Normal CRUD API requests complete within 1 second at the 95th percentile under 10 concurrent users, excluding an explicitly reported cold start. | Load test with representative data. |
| NFR-PERF-003 | The workload supports at least 1,000 API requests per day without exceeding selected free allowances under expected use. | Capacity calculation and usage-metric review. |
| NFR-PERF-004 | Pagination is required for endpoints that can return an unbounded collection. Default and maximum page sizes are explicit. | API contract and integration tests. |

## Cost optimization

| ID | Requirement | Verification |
|---|---|---|
| NFR-COST-001 | Target cost is EUR 0 per month per cloud while within applicable allowances. | Pre-deployment cost review and billing dashboard evidence. |
| NFR-COST-002 | Configure a warning at EUR 1 and a critical alert at EUR 5 per cloud where provider tooling permits. Alerts do not constitute a hard spending cap. | Budget configuration test and notification evidence. |
| NFR-COST-003 | Training resources carry `owner`, `project`, `environment`, `managed-by`, `cost-centre`, and `expires-at` metadata where supported. | Policy-as-Code tests. |
| NFR-COST-004 | AWS workload resources, especially RDS, are destroyed after each exercise unless an explicit active-session exception exists. | Destruction runbook and post-destroy resource inventory. |
| NFR-COST-005 | Azure resources may remain deployed only when their configuration and measured use remain within a free allowance. | Monthly allowance review and inventory. |
| NFR-COST-006 | NAT gateways, managed firewalls, private endpoints, premium SKUs, multi-AZ databases, and other approved cost exceptions default to disabled. | Terraform plan policy. |

## Operational excellence

| ID | Requirement | Verification |
|---|---|---|
| NFR-OPS-001 | Infrastructure, policy, application configuration, database migrations, and documentation are version controlled. Portal-only configuration is prohibited except documented account bootstrap actions. | Repository and drift review. |
| NFR-OPS-002 | Plan and apply use separate permissions. Apply requires reviewed plan output and an approval gate. | Pipeline and IAM review. |
| NFR-OPS-003 | Logs use structured records, UTC timestamps, severity, service, environment, and correlation ID. Tokens, credentials, and sensitive request content are excluded. | Log schema and redaction tests. |
| NFR-OPS-004 | Log retention is explicit and short enough to remain within the training allowance; the initial target is seven days where supported. | Terraform configuration and runtime check. |
| NFR-OPS-005 | Deployment, validation, recovery/reseed, and destruction have tested runbooks. | Runbook execution evidence. |
| NFR-OPS-006 | Architecture diagrams, ADRs, API documentation, Terraform references, threat model, and risk register change with the implementation they describe. | Pull-request documentation check. |

## Portability and maintainability

| ID | Requirement | Verification |
|---|---|---|
| NFR-MNT-001 | Business rules and API contracts remain cloud-neutral. Provider SDK use is isolated behind infrastructure or adapter boundaries. | Architecture and dependency review. |
| NFR-MNT-002 | Entity Framework Core supports Azure SQL and PostgreSQL through provider-specific configuration without conditional business logic. | Integration tests against both database engines. |
| NFR-MNT-003 | Azure and AWS use separate Terraform root modules and state files while sharing naming, tagging, policy intent, and validation conventions. | Terraform repository review. |
| NFR-MNT-004 | Provider and module versions, container bases, .NET SDK, Node.js, and package dependencies are pinned or lock-file controlled. | Reproducible build and dependency-policy checks. |

## Accessibility and compatibility

| ID | Requirement | Verification |
|---|---|---|
| NFR-UX-001 | Core workflows are keyboard operable and use semantic labels, visible focus, sufficient contrast, and meaningful error messages. | Automated accessibility scan and manual keyboard test. |
| NFR-UX-002 | Core workflows pass smoke tests on current stable Chrome, Edge, Firefox, and Safari. | Browser test matrix. |

## Review cadence

Review these requirements when a service, environment, data classification, authentication flow, cost allowance, or target workload changes. Record material changes in an ADR and update the threat model in the same change.
