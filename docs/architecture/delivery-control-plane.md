# Delivery and Terraform state control plane

- Status: Accepted baseline
- Decisions: [ADR-0006](../adrs/0006-terraform-remote-state.md) and [ADR-0007](../adrs/0007-github-actions-oidc-delivery.md)

![Multi-cloud delivery and Terraform state control plane](diagrams/delivery-control-plane.svg)

A [PNG rendering](diagrams/delivery-control-plane.png) is available for tools that do not display SVG.

## Key controls

- A private GitHub repository is the reviewed source of application, infrastructure, policy, and documentation changes.
- Pull requests run documentation, build, test, security, Terraform, and OPA/Rego checks.
- Azure and AWS each have separate read-oriented plan and privileged apply identities.
- GitHub obtains short-lived cloud identity through OIDC; long-lived cloud credentials are prohibited.
- Protected GitHub environments require approval before apply.
- Apply consumes the exact reviewed plan and verifies its checksum.
- Azure Blob Storage and Amazon S3 hold separate encrypted, versioned, locked state.
- CI concurrency is serialized per cloud, environment, stack, and state key.
- Runtime identities cannot deploy infrastructure or read Terraform state.

## Bootstrap boundary

The remote backends and OIDC trust relationships require a documented one-time privileged bootstrap. After bootstrap, local migration artifacts and privileged temporary credentials are removed, and normal changes use the gated workflow.
