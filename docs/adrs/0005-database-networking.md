# ADR-0005: Use low-cost provider-specific database network boundaries

- Status: Accepted
- Date: 2026-07-21

## Context

The reference workload uses Azure SQL Database on Azure and PostgreSQL on Amazon RDS. A production design would normally prefer private connectivity everywhere, but Azure private endpoints, private DNS, NAT, proxies, and equivalent enterprise network components can create ongoing charges that conflict with the training cost objective.

The database must never be directly reachable from a browser. Only the API workload and explicitly authorized short-lived administration paths may connect.

## Decision

### Azure

- Use the Azure SQL Database free serverless offer.
- Set public network access to `Selected networks`, not unrestricted access.
- Permit only the known Azure Container Apps environment egress addresses required by the API.
- Do not enable `Allow Azure services and resources to access this server` because that rule permits connections from resources outside this subscription.
- Permit a developer or migration runner IP only through an explicit, temporary, expiring firewall exception.
- Use TLS and managed identity with Microsoft Entra database authentication for the runtime API.
- Keep SQL username/password administration limited to bootstrap or recovery where unavoidable; never expose it to the application.
- Represent private endpoint, private DNS, and VNet-integrated Container Apps as a disabled enterprise extension.

If the Container Apps egress addresses cannot be represented as stable explicit rules, deployment is blocked until a documented exception is reviewed. The broad Azure-services firewall rule is not an automatic fallback.

### AWS

- Use a single-AZ, smallest-approved Amazon RDS for PostgreSQL instance while Free Plan credits are available.
- Set `publicly_accessible = false`.
- Place RDS in a DB subnet group spanning at least two private subnets, while the database instance itself remains single-AZ.
- Attach Lambda to the same VPC and private subnets.
- Permit PostgreSQL ingress only from the Lambda security group; do not use CIDR-wide database ingress.
- Restrict Lambda egress to the RDS security group and required database port where practical.
- Do not deploy a NAT Gateway.
- Use API Gateway JWT authorization so Lambda does not require internet access to retrieve Cognito signing keys.
- Do not deploy RDS Proxy in the initial profile. Limit Lambda database concurrency and use short, pooled connections appropriate to the workload.
- Prefer IAM database authentication for runtime access. If bootstrap administration requires a managed RDS secret, record its small Secrets Manager cost and remove the environment after testing.

## Consequences

- AWS has the stronger initial network boundary because RDS has no public address.
- Azure retains a public service endpoint protected by explicit firewall rules, identity, TLS, and synthetic-data restrictions. This is an accepted training risk, not an enterprise recommendation.
- Azure egress address changes require Terraform to update firewall rules before the old rules are removed.
- Local database administration requires an intentional temporary access path or a controlled migration job.
- Lambda has no general internet egress. Features that call arbitrary public services require a new ADR and cost/security review.
- Without RDS Proxy, concurrency must remain bounded to avoid exhausting PostgreSQL connections.

## Alternatives considered

### Azure Private Link and private DNS from the start

Deferred because it expands the paid network footprint. It is the preferred upgrade for production-like use.

### Allow all Azure services to access Azure SQL

Rejected because Microsoft documents that the rule also permits connection attempts from Azure resources in other customers' subscriptions.

### Public Amazon RDS with IP restrictions

Rejected. Lambda and RDS can communicate privately in the same VPC without a NAT Gateway.

### RDS Proxy

Deferred because it adds cost. Reconsider if concurrency or connection churn becomes material.

### Run PostgreSQL inside Lambda or a container

Rejected because ephemeral compute is not an appropriate durable relational database and would weaken the learning objective.

## Validation

- Network tests prove that the browser and an unapproved external client cannot connect to either database.
- Terraform policies reject public RDS, broad database ingress, the Azure all-services firewall rule, and non-expiring administrator firewall rules.
- Application integration tests verify encrypted connections to both database engines.
- AWS tests verify that Lambda operates without a NAT Gateway.
- A controlled migration/reseed path is tested on both clouds.

## References

- [Azure SQL IP firewall rules](https://learn.microsoft.com/en-us/azure/azure-sql/database/firewall-configure?view=azuresql)
- [Azure SQL connectivity settings](https://learn.microsoft.com/en-us/azure/azure-sql/database/connectivity-settings?view=azuresql)
- [Amazon RDS and Lambda connectivity](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/lambda-rds-connect.html)
- [Amazon RDS private access](https://docs.aws.amazon.com/AmazonRDS/latest/gettingstartedguide/security-public-private.html)
