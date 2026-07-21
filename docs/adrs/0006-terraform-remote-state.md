# ADR-0006: Use separate encrypted remote Terraform state per cloud

- Status: Accepted
- Date: 2026-07-21

## Context

Terraform state can contain sensitive infrastructure metadata and, depending on provider behavior, secret values. Local state is unsuitable for reviewed CI/CD, concurrent operations, recovery, and separation between Azure and AWS.

A single cross-cloud state would increase blast radius and couple two independently deployable environments. A paid Terraform management platform is unnecessary for the initial training scope.

## Decision

- Maintain independent state boundaries for:
  - Azure backend bootstrap.
  - Azure training landing zone and workload.
  - AWS backend bootstrap.
  - AWS training landing zone and workload.
- Azure uses the Terraform `azurerm` backend:
  - Dedicated storage account and private blob container.
  - Provider-managed encryption at rest.
  - Blob versioning and soft delete where the cost remains negligible.
  - Native blob lease locking and consistency checks.
  - Microsoft Entra ID/OIDC authentication; storage account keys and SAS tokens are prohibited for CI.
- AWS uses the Terraform `s3` backend:
  - Dedicated private S3 bucket with Block Public Access.
  - Server-side encryption and bucket versioning.
  - Native S3 lock file with `use_lockfile = true`.
  - DynamoDB locking is not used because HashiCorp marks that mechanism as deprecated.
  - OIDC-assumed IAM roles with access restricted to the required bucket prefixes and lock objects.
- Backend configuration contains no credentials. Non-secret backend coordinates are supplied through partial configuration.
- State keys include project, cloud, environment, and stack names.
- Terraform workspaces are not used to represent Azure versus AWS or unrelated lifecycle boundaries.
- Saved plan files are treated as sensitive, retained only for the approval window, and never committed.
- CI concurrency is serialized per state key in addition to backend locking.

## Bootstrap procedure

1. Run a minimal provider-specific bootstrap root locally with an authenticated administrator session.
2. Create only the remote-state storage, recovery controls, and least-privilege backend identities/policies.
3. Migrate the bootstrap state into the newly created remote backend.
4. Verify remote locking, version recovery, and access denial for unauthorized identities.
5. Use the remote backend for every subsequent plan and apply.

The bootstrap procedure is documented and idempotent. Bootstrap credentials and local migration artifacts are removed after verification.

## Consequences

- Azure and AWS can be planned, deployed, recovered, and destroyed independently.
- Compromise or corruption of one backend does not automatically expose the other cloud's state.
- Two small storage backends remain after workload destruction and can produce negligible storage/transaction costs.
- Backend bootstrap requires a carefully documented one-time privileged operation.
- State encryption does not make secret values safe to expose; Terraform configuration must still avoid placing secrets in state where provider features offer a safer alternative.

## Alternatives considered

### Commit encrypted state to Git

Rejected because it complicates locking, access revocation, secret rotation, and safe review.

### Use local state only

Rejected because it cannot safely support CI, collaboration, reliable locking, or recovery.

### Use one backend and state for both clouds

Rejected because it expands blast radius and prevents independent lifecycle management.

### HCP Terraform

Deferred. It provides managed execution and policy features, but provider-native backends better demonstrate the underlying controls and avoid another platform dependency.

### DynamoDB-based S3 locking

Rejected for new implementation because native S3 lock files are available and DynamoDB locking is deprecated.

## Validation

- Concurrent-plan test confirms each backend lock prevents conflicting state writes.
- Version-recovery exercise restores a prior state object.
- Access tests prove plan and apply identities can reach only their cloud and required state key.
- Secret and repository scans confirm state and plan files are absent from Git.
- Destroying a workload does not destroy its backend accidentally.

## References

- [Terraform AzureRM backend](https://developer.hashicorp.com/terraform/language/backend/azurerm)
- [Terraform S3 backend and native lock files](https://developer.hashicorp.com/terraform/language/backend/s3)
- [Terraform remote state storage and locking](https://developer.hashicorp.com/terraform/language/state/backends)
