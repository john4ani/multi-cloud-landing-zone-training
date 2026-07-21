# Multi-Cloud Landing Zone Training

This repository is a learning implementation of an extensible, workload-focused landing zone for Microsoft Azure and AWS.

The reference workload uses Angular 22, ASP.NET Core on .NET 10, Azure SQL in Azure, PostgreSQL on AWS, Terraform, Policy as Code, and Documentation as Code.

## Start here

1. [Project requirements](docs/requirements.md)
2. [Architecture overview](docs/architecture/overview.md)
3. [Azure deployment architecture](docs/architecture/azure-deployment.md)
4. [AWS deployment architecture](docs/architecture/aws-deployment.md)
5. [Delivery and Terraform state control plane](docs/architecture/delivery-control-plane.md)
6. [Architecture Decision Records](docs/adrs/README.md)
7. [Local development](docs/development/getting-started.md)
8. [Implementation status](docs/development/implementation-status.md)
9. [Policy-as-Code design](docs/security/policy-as-code.md)

## Repository layout

- `application/backend`: .NET 10 API, portable domain/application layers, EF Core providers, and tests.
- `application/web-angular`: Angular browser application.
- `infrastructure`: separate Azure/AWS bootstrap, environment, and reusable module roots.
- `policies`: Rego rules and tests for Terraform plan JSON.
- `docs`: architecture, ADRs, security material, requirements, and development guides.
- `.github`: validation automation, dependency updates, and protected-file ownership.

## Current status

The first application and delivery scaffold is implemented. Cloud workload creation remains disabled by default and the full private API/database stacks are the next implementation slice. See the [implementation status](docs/development/implementation-status.md) for an exact boundary between implemented resources and the target diagrams.

## Documentation principle

Documentation is part of the product. A change is not complete when it changes architecture, behavior, security, deployment, cost, operations, or interfaces without updating the relevant documentation in the same change.
