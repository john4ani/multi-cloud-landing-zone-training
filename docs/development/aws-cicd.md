# AWS CI/CD setup and operation

The AWS delivery lane uses GitHub Actions, short-lived AWS OIDC sessions, separate plan/apply roles, protected environments, Policy as Code, immutable Lambda and Angular artifacts, an exact saved Terraform plan, private database migration, smoke tests, and guarded destruction.

## One-time AWS bootstrap

The GitHub trust policy must use the exact repository portion of the OIDC `sub` claim.

- Legacy subject example: `repo:owner/repository`
- Immutable subject example: `repo:owner@owner-id/repository@repository-id`

GitHub repositories using immutable OIDC subjects include the numeric owner and repository IDs. Do not guess which form applies. Confirm the repository OIDC setting or inspect a diagnostic token before bootstrapping the trust.

Run the bootstrap locally with an AWS identity allowed to create the state bucket, OIDC provider, IAM roles, and policies:

```powershell
cd infrastructure/bootstrap/aws
terraform init
terraform apply `
  -var='configure_github_oidc=true' `
  -var='github_oidc_repository_subject=repo:<owner>/<repository>'
terraform output
```

If `token.actions.githubusercontent.com` is already registered as an OIDC provider in the AWS account, also set:

```powershell
-var='create_github_oidc_provider=false'
```

The bootstrap creates:

- A private, encrypted, versioned S3 state bucket with HTTPS enforced.
- A plan role trusted only for same-repository pull requests, `main`, and `aws-training-plan`.
- An apply role trusted only through the `aws-training` environment.
- View-only plan permissions plus read access to this stack's state object.
- Apply permissions limited to the services used by this workload, network-only EC2 actions, the `cloud-training-web-*` bucket namespace, the exact state/lock objects, and `cloud-training-*` Lambda execution roles.

Bootstrap resources survive the workload destroy workflow by design.

## GitHub configuration

Create these repository variables from the bootstrap output:

| Variable | Value |
|---|---|
| `AWS_ACCOUNT_ID` | `aws_account_id` |
| `AWS_REGION` | Bootstrap region, normally `eu-central-1` |
| `AWS_TFSTATE_BUCKET` | `bucket_name` |
| `AWS_PLAN_ROLE_ARN` | `github_plan_role_arn` |
| `AWS_APPLY_ROLE_ARN` | `github_apply_role_arn` |

Set optional repository variable `AWS_AUTHENTICATION_ENABLED` to `true` only for an approved Cognito sign-in deployment. Its absence or `false` keeps browser sign-in and JWT enforcement disabled.

Create two GitHub environments:

1. `aws-training-plan` protects creation of the deployable exact plan.
2. `aws-training` protects application of that plan and destruction.

Configure required reviewers on both environments. Add the same environment secret named `AWS_DATABASE_ADMIN_PASSWORD` to both. Use a unique value of at least 16 characters. It is an RDS bootstrap credential, not an AWS access key.

For an authenticated smoke test, add a short-lived access token as environment secret `AWS_AUTHENTICATION_TEST_ACCESS_TOKEN`. Remove it after the exercise. It is optional while authentication is disabled.

Do not create `AWS_ACCESS_KEY_ID` or `AWS_SECRET_ACCESS_KEY` secrets. The workflows request a GitHub OIDC token and exchange it for a short-lived role session. Each credential action also verifies the expected AWS account ID.

## Workflows

- `Validate` runs application tests, migration generation, Terraform/Rego checks, workflow hardening, and Trivy scanning.
- `AWS Plan` builds the Lambda ZIP and creates a read-only speculative plan for same-repository pull requests. Only the text plan and policy result are retained; the binary plan is not deployable.
- `AWS Deploy` is manually dispatched from `main`. Enter `DEPLOY-AWS`, an expiry date, and an optional alert email. It tests and scans the exact commit, creates immutable Lambda/frontend artifacts, creates a protected exact plan, verifies its checksum, applies it through the apply role, invokes the private migration Lambda, publishes Angular to S3, invalidates CloudFront, and runs API/database/frontend smoke tests.
- `AWS Destroy` is manually dispatched from `main`. Enter `DESTROY-AWS`; the protected apply role creates and applies a checked destroy plan, then verifies no resources remain with the workload tags.

Deploy and destroy share one concurrency group, so they cannot modify the AWS state simultaneously. Fork pull requests do not receive an AWS token.

The workload Terraform creates the Cognito SPA client, hosted domain, callback/logout URLs, and `User`/`Administrator` groups. The deploy workflow generates Angular runtime configuration from the Terraform outputs. Create only synthetic users and assign groups using the [authentication guide](authentication.md#amazon-cognito-setup).

## Required GitHub controls

- Require `Validate` and `AWS Plan / plan` before merging AWS changes.
- Require CODEOWNERS review for workflows, policies, infrastructure, and ADRs.
- Do not bypass either environment approval.
- Keep Actions restricted to the pinned actions used by this repository.
- Retain exact-plan and build artifacts for one day only.
- Never upload Terraform state, credentials, migration request payloads, or `tfplan.json`.

## Operating the lane

1. Run `AWS Plan` or open a same-repository pull request and review the text plan plus empty OPA denial result.
2. From `main`, dispatch `AWS Deploy`.
3. Enter `DEPLOY-AWS`, a near-term `YYYY-MM-DD` expiry date, and optionally an alert email.
4. Approve `aws-training-plan` only after reviewing cost-sensitive inputs and the exact-plan evidence.
5. Approve `aws-training` to apply that saved plan.
6. Confirm the migration, CRUD smoke test, budget, alarm, SNS subscription, and deployed URLs.
7. Dispatch `AWS Destroy` with `DESTROY-AWS` as soon as testing is complete.

RDS is the principal cost risk. GitHub approvals, AWS Budgets, and CloudWatch alarms are preventive/detective controls, not a billing cap.

## Expected retained resources

After `AWS Destroy`, the workload Terraform state remains in the state bucket. The state bucket, versions, GitHub OIDC provider when created by this bootstrap, plan/apply roles, and their policies also remain. Remove bootstrap resources manually only when the entire exercise is retired and the state is no longer required.
