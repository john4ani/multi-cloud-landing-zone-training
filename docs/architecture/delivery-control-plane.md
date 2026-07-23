# Delivery and Terraform state control plane

- Status: Azure and AWS lanes implemented
- Decisions: [ADR-0006](../adrs/0006-terraform-remote-state.md) and [ADR-0007](../adrs/0007-github-actions-oidc-delivery.md)

![Multi-cloud delivery and Terraform state control plane](diagrams/delivery-control-plane.svg)

A [PNG rendering](diagrams/delivery-control-plane.png) is available for tools that do not display SVG.

## Key controls

- A private GitHub repository is the reviewed source of application, infrastructure, policy, and documentation changes.
- Pull requests run documentation, build, test, security, Terraform, and OPA/Rego checks.
- Azure and AWS each have separate read-oriented plan and privileged apply identities.
- GitHub obtains short-lived cloud identity through OIDC; long-lived cloud credentials are prohibited.
- Each cloud uses separate protected plan and apply environments; the first protects the exact plan and database bootstrap secret, and the second protects apply/destroy permission.
- Apply consumes the exact reviewed plan and verifies its checksum.
- Azure deploy continues through SQL migration, Angular publication, API/database/frontend smoke tests, and revocation of the temporary Static Web Apps token.
- AWS deploy continues through private PostgreSQL migration, S3 publication, CloudFront invalidation, and API/database/frontend smoke tests.
- Azure Blob Storage and Amazon S3 hold separate encrypted, versioned, locked state.
- CI concurrency is serialized per cloud, environment, stack, and state key.
- Runtime identities cannot deploy infrastructure or read Terraform state.

## Bootstrap boundary

The remote backends and OIDC trust relationships require a documented one-time privileged bootstrap. Azure retains its empty workload resource group so permissions stay resource-group-scoped. AWS retains its state bucket and separate plan/apply roles; the apply policy is limited to the workload's services, network operations, bucket namespace, state objects, and execution-role prefix. See the [Azure CI/CD runbook](../development/azure-cicd.md) and [AWS CI/CD runbook](../development/aws-cicd.md).
