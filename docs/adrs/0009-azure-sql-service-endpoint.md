# ADR-0009: Use a VNet service endpoint for the Azure SQL training boundary

- Status: Accepted
- Date: 2026-07-22
- Supersedes: The Azure egress-IP decision in ADR-0005

## Context

ADR-0005 proposed allowing known Azure Container Apps environment egress IP addresses through Azure SQL firewall rules. Consumption-environment outbound addresses are not guaranteed to remain static. Depending on them would make the database boundary drift or fail unexpectedly. NAT Gateway, Azure Firewall, and Private Link provide stronger or predictable networking but introduce paid components that conflict with the low-cost training profile.

Azure SQL supports virtual-network rules backed by a `Microsoft.Sql` service endpoint. A Container Apps workload-profiles environment can integrate with a dedicated delegated subnet. This provides a stable subnet identity without a NAT Gateway or permanent client-IP rule.

## Decision

- Deploy the Container Apps consumption workload profile into a dedicated `/27` subnet.
- Enable the `Microsoft.Sql` service endpoint on that subnet.
- Add exactly one Azure SQL virtual-network rule for the Container Apps subnet.
- Keep Azure SQL public network access enabled only because the service endpoint uses the public PaaS endpoint.
- Do not add the broad `0.0.0.0` Azure-services firewall rule or a permanent administrator IP rule.
- Permit a single client IP only during the explicit migration/bootstrap script and remove it in `finally` cleanup.
- Continue using TLS 1.2, managed identity, Entra database users, synthetic data, and provider-managed encryption.
- Keep Private Link plus private DNS as the preferred enterprise upgrade and a disabled, costed extension.

## Consequences

- The Container Apps-to-database path is identified by subnet rather than unstable outbound IP addresses.
- Traffic reaches the Azure SQL service endpoint over the Azure backbone, but the SQL logical server still has a public endpoint; this remains a documented training trade-off.
- The Container Apps environment requires a customer-managed VNet and delegated subnet.
- Migration from a developer workstation requires a deliberately temporary single-IP rule.
- Policy-as-Code can reject missing VNet rules, broad SQL firewall rules, paid network components, and non-free database exhaustion behavior.

## Validation

- Terraform validates the delegated subnet, service endpoints, and SQL virtual-network rule.
- OPA tests reject Azure SQL public access when no virtual-network rule exists.
- OPA tests reject `0.0.0.0`, address ranges, paid private-networking components, and billing after free-limit exhaustion.
- The migration script removes its temporary firewall rule on success and failure.
- A cloud smoke test must confirm that the API connects using its managed identity and that an unapproved external client cannot connect.
