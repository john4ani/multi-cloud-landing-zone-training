# ADR-0003: Adopt the initial low-cost deployment profiles

- Status: Accepted
- Date: 2026-07-21

## Context

The training solution must demonstrate a working Angular, ASP.NET Core, and relational database workload on Azure and AWS while minimizing cost. A full enterprise landing zone and all enterprise security services would introduce unnecessary complexity and ongoing charges.

## Decision

Adopt the following initial deployment profiles:

### Azure

- Azure Static Web Apps free tier for Angular hosting and HTTPS ingress.
- Azure Container Apps consumption profile for the ASP.NET Core API.
- Azure SQL Database free serverless offer for relational persistence.
- Managed identity, Azure Policy, budgets, and monitoring within free allowances.
- Private endpoints and advanced centralized network controls remain documented extensions and are disabled initially.

### AWS

- Amazon CloudFront with a private Amazon S3 origin for Angular hosting.
- Amazon API Gateway HTTP API and AWS Lambda for the ASP.NET Core API.
- Private Amazon RDS for PostgreSQL using time-limited AWS Free Plan credits.
- A workload VPC without a NAT Gateway.
- IAM guardrails, AWS Budgets, and short-retention CloudWatch telemetry.
- AWS Organizations, centralized inspection, and centralized security accounts remain documented extensions.

## Consequences

- The Azure workload can remain free only while it stays within each service allowance.
- The AWS database is not permanently free and must be destroyed when testing is complete.
- Budgets and alerts improve visibility but do not impose a universal hard spending cap.
- Some enterprise security controls are represented as extension paths rather than deployed resources.
- Terraform policies must block unapproved expensive resources in the training profile.
- Service selections can be replaced through later ADRs without changing the portable application contract.
