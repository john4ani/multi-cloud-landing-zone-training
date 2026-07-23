# AWS training platform module
This module implements the low-cost AWS workload accepted in ADR-0003, ADR-0005, and ADR-0010:

- private, encrypted, versioned S3 Angular origin;
- CloudFront OAC, HTTPS redirection, security headers, SPA fallback, and uncached API behaviors;
- API Gateway HTTP API with throttling and a conditional Cognito JWT authorizer;
- .NET 10 API and explicit database-migration Lambda functions;
- private two-subnet VPC without internet/NAT routes;
- security-group-referenced Lambda-to-RDS access on PostgreSQL only;
- encrypted, single-AZ, fixed-size RDS PostgreSQL with IAM authentication;
- narrowly scoped runtime and migration IAM roles;
- short-retention CloudWatch logs, bounded concurrency, alarms, SNS, and AWS Budget;
- Cognito Authorization Code/PKCE SPA resources for the later login-adapter slice.

Deployment is opt-in at the environment root and requires a reviewed Lambda ZIP plus a write-only database bootstrap password. RDS is not permanently free; destroy the workload after testing.
