# Infrastructure as Code

This directory separates remote-state bootstrap from the Azure and AWS workload stacks. Run bootstrap once with a privileged local identity, then configure each environment backend without committing credentials.

Workload creation is disabled by default. Review the plan, free-tier eligibility, region availability, and the current pricing pages before setting `deploy_workload = true`. A cloud account can still charge for network egress, logs, DNS, database overage, or resources left running.

See [ADR-0006](../docs/adrs/0006-terraform-remote-state.md) and the [local development guide](../docs/development/getting-started.md).
