# Architecture overview

Status: Proposed

These diagrams describe intent. Exact service selections can change through Architecture Decision Records before implementation.

## System context

```mermaid
flowchart LR
    user["Browser user"]
    engineer["Platform or application engineer"]
    repo["Version-controlled source\nApplication, Terraform, policies, documentation"]
    pipeline["Validation and deployment pipeline"]
    azure["Azure application landing zone"]
    aws["AWS workload environment"]

    user -->|"HTTPS"| azure
    user -->|"HTTPS"| aws
    engineer -->|"Proposes changes"| repo
    repo --> pipeline
    pipeline -->|"Terraform deployment"| azure
    pipeline -->|"Terraform deployment"| aws
```

## Portable workload and cloud-specific infrastructure

```mermaid
flowchart TB
    browser["Supported browser"]

    subgraph portable["Portable application"]
        web["Angular web application"]
        api["ASP.NET Core Web API"]
        data["Entity Framework Core and application data contract"]
        web -->|"HTTPS and JSON"| api
        api --> data
    end

    subgraph az["Azure implementation"]
        azedge["Static web hosting and HTTPS ingress"]
        azcompute["Serverless or consumption-based API compute"]
        azsql["Azure SQL Database"]
        azidentity["Managed identity and Microsoft Entra ID"]
        azedge --> azcompute
        azcompute --> azsql
        azidentity -.-> azcompute
        azidentity -.-> azsql
    end

    subgraph aw["AWS implementation"]
        awedge["Static web hosting and HTTPS ingress"]
        awcompute["Serverless API compute"]
        awdb["PostgreSQL-compatible database"]
        awidentity["IAM execution role"]
        awedge --> awcompute
        awcompute --> awdb
        awidentity -.-> awcompute
        awidentity -.-> awdb
    end

    browser --> web
    portable -.->|"Deployment target"| az
    portable -.->|"Deployment target"| aw
```

## Landing-zone capabilities

```mermaid
flowchart TB
    workload["Reference workload"]
    identity["Identity and least privilege"]
    governance["Policy and resource governance"]
    network["Network boundaries and HTTPS ingress"]
    security["Secrets, encryption, and scanning"]
    operations["Logs, health checks, and runbooks"]
    cost["Budgets, allowed services, and expiry controls"]
    automation["Terraform and delivery pipeline"]

    identity --> workload
    governance --> workload
    network --> workload
    security --> workload
    operations --> workload
    cost --> workload
    automation --> workload
```

The initial implementation contains only capabilities required by the reference workload. Each capability is exposed through a documented module boundary so that enterprise implementations can add shared networking, centralized logging, additional accounts or subscriptions, and advanced security services later.

## Delivery and policy enforcement

```mermaid
flowchart LR
    change["Application, infrastructure, policy, or documentation change"]
    static["Format, lint, unit test, secret scan"]
    plan["Terraform plan"]
    planjson["Terraform plan JSON"]
    opa["OPA/Rego policy evaluation"]
    approval["Human review and approval"]
    apply["Terraform apply"]
    native["Azure Policy or AWS guardrails"]
    smoke["Application and security smoke tests"]

    change --> static --> plan --> planjson --> opa
    opa -->|"Allowed"| approval --> apply --> native --> smoke
    opa -->|"Denied with reasons"| change
```

## Well-Architected mapping

| Pillar | Initial evidence |
|---|---|
| Reliability | Health endpoints, repeatable deployments, smoke tests, documented recovery and destruction |
| Security | Least privilege, short-lived identity, encrypted transport, protected databases, policy gates |
| Cost Optimization | Small approved services, budgets, expiry tags, expensive-resource deny policies |
| Operational Excellence | IaC, CI checks, ADRs, runbooks, observable deployment and application behavior |
| Performance Efficiency | Serverless or consumption-based scaling, browser and API performance tests |

## Known training trade-offs

Private endpoints, enterprise firewalls, multi-region redundancy, centralized security operations, and long-term log retention can create material charges. They will be documented as extension modules rather than enabled in the zero-cost profile.
