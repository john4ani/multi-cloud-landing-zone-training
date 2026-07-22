# Azure deployment runbook

This runbook deploys the training workload only after a reviewed Terraform plan. It does not configure the remote-state bootstrap, publish the API image, create Entra application registrations, or guarantee a zero invoice.

## Prerequisites

- Azure CLI authenticated to the intended subscription with MFA.
- Terraform 1.13.x.
- AzureRM backend created through `infrastructure/bootstrap/azure`.
- An immutable, vulnerability-scanned public API image reference ending in `@sha256:<digest>`. The low-cost slice does not create a paid private registry.
- `sqlcmd` for the explicit database bootstrap step.
- A subscription eligible for the Azure SQL Database free offer in the selected region.

## Prepare configuration

From `infrastructure/environments/azure-training`:

```powershell
Copy-Item terraform.tfvars.example terraform.tfvars
Copy-Item backend.hcl.example backend.hcl
```

Edit the local, ignored files. Keep `deploy_workload = false` while reviewing inputs. Set `expires_at` to the planned destruction or review date and `budget_start_date` to the first day of the current month.

Supply the bootstrap-only SQL password through the process environment, never a file:

```powershell
$env:TF_VAR_sql_admin_password = '<strong-unique-password>'
```

The provider uses write-only password support, so the value is not returned in normal Terraform state. Protect the environment and process regardless.

## Initialize, validate, and plan

```powershell
terraform init -backend-config=backend.hcl
terraform fmt -check -recursive
terraform validate
terraform plan -out tfplan
terraform show -json tfplan > tfplan.json
opa eval --data ../../../policies/rego --input tfplan.json "data.terraform.security.deny"
```

Review the plan for the exact subscription, region, SKUs, tags, free-limit settings, public endpoints, and absence of NAT Gateway, Azure Firewall, Private Endpoints, or broad SQL firewall rules. Confirm the policy result is empty.

## Apply infrastructure

Change `deploy_workload` to `true`, regenerate and re-review the exact plan, then apply only that saved plan:

```powershell
terraform plan -out tfplan
terraform apply tfplan
terraform output -json deployment
```

The API health endpoint can respond before database bootstrap, but CRUD requests will fail until the schema and managed-identity database user are created.

## Apply migrations and authorize the runtime identity

Obtain the deployment output and your current public IPv4 address. From the repository root, run:

```powershell
./scripts/migrate-azure.ps1 `
  -ResourceGroupName '<resource-group>' `
  -SqlServerName '<logical-server-name>' `
  -DatabaseName 'cloud_training' `
  -RuntimeIdentityName '<api-identity-name>' `
  -RuntimeIdentityPrincipalId '<api-identity-principal-id>' `
  -ClientIp '<your-current-public-ip>'
```

The script creates a single-IP firewall rule, authenticates with the signed-in Entra identity, applies the SQL Server EF Core migrations, creates the contained managed-identity user with data-reader/data-writer roles, and removes the rule in `finally` cleanup. The runtime identity does not receive schema-owner permission.

## Smoke test and evidence

```powershell
$deployment = terraform output -json deployment | ConvertFrom-Json
Invoke-RestMethod "https://$($deployment.api_fqdn)/health"
Invoke-RestMethod "https://$($deployment.api_fqdn)/api/topics"
```

Capture the reviewed plan hash, empty OPA denial result, apply result, migration result, health response, budget configuration, and Azure resource inventory. Authentication remains disabled until the Entra login-adapter slice is complete.

## Destroy

```powershell
terraform plan -destroy -out destroy.tfplan
terraform apply destroy.tfplan
az resource list --resource-group '<resource-group>' --output table
```

Verify that no temporary SQL firewall rule, resource-group resource, or unexpected provider-managed resource remains. Azure budgets alert; they are not hard spending caps.
