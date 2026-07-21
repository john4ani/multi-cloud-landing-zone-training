# AWS deployment architecture

Status: Accepted baseline

This is the initial low-cost AWS deployment. RDS consumption is expected to use the time-limited AWS Free Plan credits and must be destroyed when the exercise is not active.

![AWS low-cost landing-zone deployment](diagrams/aws-deployment.svg)

The editable SVG uses official AWS architecture icons. A [PNG rendering](diagrams/aws-deployment.png) is also available for tools that do not display SVG.

## Trust and traffic decisions

- The browser authenticates with Amazon Cognito using Authorization Code with PKCE.
- API Gateway validates Cognito JWTs before invoking Lambda; application authorization still enforces normalized roles and ownership.
- The S3 bucket is private; CloudFront uses Origin Access Control.
- Only CloudFront and API Gateway are public application entry points.
- PostgreSQL is private and accepts traffic only from the Lambda security group, with IAM database authentication preferred for runtime access.
- The VPC has no NAT Gateway in the training profile because a NAT Gateway creates ongoing charges.
- The deployment role and Lambda execution role use separate, least-privilege permissions.
- Log retention is explicit to prevent indefinite storage growth.

## Items requiring an ADR

- Lambda ASP.NET Core hosting model and cold-start trade-offs.
- RDS PostgreSQL size, lifecycle, authentication, and Free Plan limitations.
- Monitoring configuration that remains within the selected free allowance.
