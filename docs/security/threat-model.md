# Threat model

- Status: Accepted baseline
- Method: STRIDE with likelihood and impact scoring
- Scope: Angular browser application, ASP.NET Core API, relational persistence, CI/CD, Terraform, Azure training environment, and AWS training environment
- Data classification: Synthetic training data only

## Security objectives

- Only authenticated users access business functionality.
- Users access only their own records unless an explicit administrator policy applies.
- Cloud and deployment access uses least privilege and short-lived identity.
- The browser never receives database credentials or direct database access.
- Infrastructure, policies, application artifacts, and documentation remain traceable to reviewed source.
- A malicious request cannot create uncontrolled cloud cost.
- Security controls remain proportionate to a non-production, synthetic-data training workload.

## Data flows and boundaries

See the [security data-flow diagram](../architecture/security-data-flow.md). Cloud-specific resource placement is shown in the [Azure](../architecture/azure-deployment.md) and [AWS](../architecture/aws-deployment.md) deployment diagrams.

## STRIDE analysis

| STRIDE category | Principal threats | Primary mitigations |
|---|---|---|
| Spoofing | Stolen or forged access token; compromised administrator; pipeline impersonation | Authorization Code with PKCE, exact JWT validation, MFA for administration, short token lifetimes, OIDC workload federation |
| Tampering | Modified request, cross-user record identifier, altered Terraform plan, compromised artifact or dependency | TLS, ownership authorization, input validation, protected reviews, immutable plan approval, lock files, scanning, policy gates |
| Repudiation | User or administrator denies an operation; deployment cannot be attributed | Correlation IDs, identity subject in security events, cloud audit logs, reviewed source history, deployment records |
| Information disclosure | Token, secret, connection string, Terraform state, database record, or sensitive log exposed | No local-storage tokens, redaction, sensitive outputs blocked, encrypted state and transport, least privilege, synthetic data only |
| Denial of service | Request flooding, expensive queries, free-tier exhaustion, database connection exhaustion | API throttling, bounded inputs and pagination, timeouts, concurrency limits, budgets, quotas, health monitoring |
| Elevation of privilege | User invokes administrator operation; API or pipeline role gains excessive cloud access | Policy-based authorization, role and ownership tests, separate deployment roles, permission boundaries, Azure Policy/OPA guardrails |

## Security requirements derived from threats

- Authentication is present in the first working release, not added later.
- Access tokens remain in browser memory and are not written to local or session storage.
- All business entities include an owner identifier enforced in the API data-access path.
- Administrator endpoints require an explicit administrator policy and are tested independently.
- The API accepts only configured issuers, audiences, algorithms, and clock skew.
- CORS permits only the deployed web origin for each environment.
- Database queries are parameterized, paginated where unbounded, and protected by command timeouts.
- Cloud deployment identities are separate from runtime identities.
- Terraform plan output is evaluated by policy and reviewed before apply.
- Logs record security-relevant outcomes but exclude tokens, secrets, connection strings, and request bodies by default.
- Error responses use stable problem details without stack traces or provider internals.
- Rate, payload-size, and concurrency limits are explicit.

## Accepted low-cost limitations

| Limitation | Reason accepted | Compensating controls | Exit condition |
|---|---|---|---|
| Azure SQL private endpoint is initially disabled. | Private networking can create ongoing charges. | Synthetic data only, narrow firewall scope, Entra/token authentication where supported, TLS, no browser access, documented exception. | Enable private endpoint and private DNS for a funded or production-like environment. |
| AWS RDS is single-AZ and temporary. | Multi-AZ adds cost; the workload is disposable. | Migrations, seed data, optional short backup, tested redeployment, 24-hour RPO. | Enable Multi-AZ and production backup policy for a production-like workload. |
| Managed WAF and centralized network inspection are disabled. | They can create ongoing charges. | Platform ingress controls, validation, security headers, throttling, quotas, provider-native edge protections, synthetic data. | Enable managed WAF and inspection when exposure or data sensitivity increases. |
| Centralized security operations and long retention are disabled. | Training scale does not justify the cost. | Short-retention logs, cloud audit history where included, local evidence captured during tests. | Enable central log archive and security monitoring for multiple workloads or accounts. |
| Budgets are alerts rather than universal hard caps. | Provider budgets do not guarantee shutdown at a threshold. | Deny expensive resources, small capacity, expiry metadata, AWS destruction after exercises, frequent billing review. | Add automated quota/action controls after validating that they cannot disrupt required account services. |

## Out of scope

- Production data, regulatory compliance certification, payment processing, and organization-wide incident response.
- Employee lifecycle management and enterprise identity governance.
- Multi-region disaster recovery and active-active availability.
- Malicious cloud-provider insiders or compromise of Azure/AWS control planes.
- Physical endpoint security beyond requiring a supported browser and MFA for administration.

## Review triggers

Reassess this model before adding real users, non-synthetic data, a new internet entry point, file upload, external integrations, administrator capabilities, new cloud services, persistent AWS deployment, or any production-like environment.

## Related artifacts

- [Non-functional requirements](../requirements/non-functional-requirements.md)
- [Risk register](risk-register.md)
- [Policy-as-Code design](policy-as-code.md)
- [Security data-flow diagram](../architecture/security-data-flow.md)
