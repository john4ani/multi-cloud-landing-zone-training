# Infrastructure as Code

This directory separates remote-state bootstrap from the Azure and AWS workload stacks. Run bootstrap once with a privileged local identity, then configure each environment backend without committing credentials.

Workload creation is disabled by default. Review the plan, free-tier eligibility, region availability, and the current pricing pages before setting `deploy_workload = true`. A cloud account can still charge for network egress, logs, DNS, database overage, or resources left running.

The protected delivery paths use separate OIDC plan/apply identities and exact saved plans. See [ADR-0006](../docs/adrs/0006-terraform-remote-state.md), [ADR-0007](../docs/adrs/0007-github-actions-oidc-delivery.md), the [Azure CI/CD guide](../docs/development/azure-cicd.md), and the [AWS CI/CD guide](../docs/development/aws-cicd.md).
