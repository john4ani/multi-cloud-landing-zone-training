# AWS deployment runbook

This runbook deploys the AWS workload manually for learning or recovery. The normal protected path is the [AWS CI/CD lane](aws-cicd.md).

## Cost and security boundary

The workload uses low-volume allowances for CloudFront, S3, API Gateway, Lambda, Cognito, SNS, and CloudWatch where eligible. Private RDS PostgreSQL is the material cost risk and can consume time-limited AWS Free Plan credits. A zero invoice is not guaranteed. Set an expiry date, confirm alert subscriptions, test promptly, and destroy the workload.

The VPC has no internet gateway or NAT Gateway. RDS has no public address. Lambda can send traffic only to the database security group on TCP 5432.

## Prerequisites

- AWS CLI authenticated with a short-lived session and MFA where applicable.
- Terraform 1.13.x and the remote S3 backend from `infrastructure/bootstrap/aws`.
- .NET SDK 10 and PowerShell 7.
- Node.js 24.18.0 for the Angular build.
- OPA 1.7.x for the plan policy gate.
- Confirmed current Free Plan/Free Tier and service availability in the selected region.

## Build the Lambda package

From the repository root:

```powershell
./scripts/build-aws-package.ps1
```

The script publishes the .NET 10 application for Linux, downloads the Amazon RDS global CA bundle, creates `artifacts/aws/cloud-architecture-training-api.zip`, and prints its SHA-256 hash. `artifacts` is ignored by Git.

## Configure and plan

```powershell
cd infrastructure/environments/aws-training
Copy-Item terraform.tfvars.example terraform.tfvars
Copy-Item backend.hcl.example backend.hcl
$env:TF_VAR_database_admin_password = '<strong-unique-bootstrap-password>'

terraform init -backend-config=backend.hcl
terraform fmt -check -recursive
terraform validate
terraform plan -out tfplan
terraform show -json tfplan > tfplan.json
opa eval --fail --data ../../../policies/rego --input tfplan.json 'count(data.terraform.security.deny) == 0'
```

Keep `deploy_workload = false` until inputs are reviewed. Then set it to `true`, regenerate the plan, review the exact resource count, instance class, 20 GiB fixed storage, expiry tags, absence of NAT/RDS Proxy, and empty OPA denial set. Apply only the saved plan:

```powershell
terraform apply tfplan
$deployment = terraform output -json deployment | ConvertFrom-Json
```

## Apply migrations

The database is private, so migration runs in the dedicated VPC Lambda. Use the same bootstrap password that was supplied to Terraform:

```powershell
$env:AWS_DATABASE_ADMIN_PASSWORD = '<same-bootstrap-password>'
./scripts/migrate-aws.ps1 -FunctionName $deployment.migration_function_name
```

The script sends the password in a temporary invocation file, deletes the file and process environment value in `finally`, and checks the safe response. The Lambda applies EF Core migrations, creates `cloud_app`, grants `rds_iam`, and grants only the required schema/data permissions.

## Publish Angular

Build the application and set its runtime API path to the same CloudFront origin:

```powershell
npm ci --prefix application/web-angular
npm run build --prefix application/web-angular

$browserConfig = @{
  apiBaseUrl = '/api'
  authentication = @{
    enabled = [bool]$deployment.authentication_enabled
    provider = 'Cognito'
    authority = $deployment.authentication_authority
    clientId = $deployment.user_pool_client_id
    scope = $deployment.authentication_scope
  }
}

"globalThis.cloudTrainingConfig = $($browserConfig | ConvertTo-Json -Compress -Depth 4);" |
  Set-Content application/web-angular/dist/web-angular/browser/config.js

aws s3 sync application/web-angular/dist/web-angular/browser `
  "s3://$($deployment.frontend_bucket_name)" `
  --delete

aws cloudfront create-invalidation `
  --distribution-id $deployment.cloudfront_distribution_id `
  --paths '/*'
```

Authentication is disabled by default. To test it, set `authentication_enabled = true` before planning, deploy, create synthetic Cognito test users, and assign the Terraform-created `User` or `Administrator` group as described in the [authentication guide](authentication.md#amazon-cognito-setup).

## Smoke test

```powershell
./scripts/smoke-test.ps1 `
  -ApiBaseUrl $deployment.api_base_url `
  -FrontendUrl $deployment.frontend_url `
  -Cloud AWS
```

When authentication is enabled, add `-AccessToken '<short-lived-access-token>'`. Never save a token in `terraform.tfvars`, Terraform state, source control, or the generated browser configuration.

Capture the reviewed plan hash, OPA result, migration response, CRUD smoke-test result, budget/SNS configuration, and resource inventory as deployment evidence.

## Destroy

From `infrastructure/environments/aws-training`:

```powershell
terraform plan -destroy -out destroy.tfplan
terraform apply destroy.tfplan
aws resourcegroupstaggingapi get-resources `
  --tag-filters Key=application,Values=cloud-architecture-training
```

Confirm that workload resources are gone. The separately bootstrapped Terraform state bucket remains. AWS Budgets and CloudWatch alarms notify; they do not stop spending automatically.
