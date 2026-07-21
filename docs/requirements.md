# Project requirements

Status: Accepted baseline

Detailed measurable requirements are maintained in the [non-functional requirements specification](requirements/non-functional-requirements.md).

## Goals

- Create a small multi-cloud landing zone that supports the reference workload on Azure and AWS.
- Keep the design modular so that it can be extended for enterprise applications.
- Apply the Azure Well-Architected Framework pillars to the workload on both clouds.
- Apply AWS-specific Well-Architected guidance to AWS implementation decisions.
- Use Terraform for repeatable infrastructure deployment.
- Demonstrate Security as Code, Policy as Code, and Documentation as Code.
- Make the application reachable and testable from a supported web browser.
- Keep the learning environment at zero or near-zero cost and make all cost risks explicit.

## Reference workload

- Angular web application using the latest supported stable release selected at implementation time.
- ASP.NET Core Web API using the latest supported .NET LTS release selected at implementation time.
- Azure SQL Database for Azure.
- PostgreSQL-compatible storage for AWS.
- Entity Framework Core with provider-specific database configuration behind a common application contract.

## Constraints

- A permanent zero-cost deployment is not guaranteed by either cloud.
- The AWS implementation may depend on time-limited Free Tier credits.
- Paid enterprise controls are optional and disabled by default in the training environment.
- Databases must never be directly accessible from a browser.
- Secrets must not be committed to source control or exposed through Terraform outputs.
- Cloud-specific infrastructure remains in separate Terraform root modules and state files.

## Documentation requirements

- Architecture diagrams are created or updated before implementation begins.
- Documentation uses Markdown and Mermaid wherever practical.
- Significant decisions are recorded as Architecture Decision Records (ADRs).
- Public API behavior is described by an OpenAPI document generated from the application.
- Terraform input and output references are generated from module definitions.
- Documentation links, formatting, and diagrams are validated in continuous integration.
- Every pull request states whether documentation is affected.
- Documentation changes are included in the same pull request as the related code change.

## Definition of Done

A change is complete only when:

- implementation and automated tests pass;
- Terraform formatting, validation, linting, and security checks pass where applicable;
- Policy-as-Code checks pass;
- relevant diagrams, ADRs, runbooks, and reference documentation are updated;
- cost and security implications are documented;
- deployment and rollback or destruction procedures are documented and tested.
