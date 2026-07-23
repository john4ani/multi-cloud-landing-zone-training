# Azure deployment runbook

The recommended deployment path is the protected GitHub Actions workflow documented in [Azure CI/CD setup and operation](azure-cicd.md). A local deployment remains available for learning and recovery.

## Pipeline deployment

1. Complete the one-time Azure bootstrap and GitHub environment setup.
2. Merge a pull request only after `Validate` and the speculative `Azure Plan` pass.
3. From GitHub Actions, run `Azure Deploy` on `main`.
4. Enter `DEPLOY-AZURE`, a `YYYY-MM-DD` destruction/review date, and optionally a budget alert email.
5. Review and approve `azure-training-plan`; inspect the saved-plan summary and empty OPA denial result.
6. Approve `azure-training` to apply that exact plan.
7. Confirm the migration, API/database CRUD, frontend, and token-rotation steps pass.

The workflow creates and scans the application artifacts. No long-lived Azure credential or Static Web Apps deployment token is stored in GitHub.

Authentication is disabled by default. To test it, complete the [Microsoft Entra ID setup](authentication.md#microsoft-entra-id-setup), configure the documented repository variables, and use an explicitly approved deployment.

## Local recovery path

Prerequisites are Azure CLI, Terraform 1.13.x, .NET 10, OPA, completed remote-state bootstrap, a public immutable API image ending in `@sha256:<digest>`, and Azure SQL free-offer eligibility.

From `infrastructure/environments/azure-training`:

```powershell
Copy-Item terraform.tfvars.example terraform.tfvars
Copy-Item backend.hcl.example backend.hcl
$env:TF_VAR_sql_admin_password = '<strong-unique-password>'
terraform init -backend-config=backend.hcl
terraform fmt -check -recursive
terraform validate
terraform plan -out tfplan
terraform show -json tfplan > tfplan.json
opa eval --fail --data ../../../policies/rego --input tfplan.json 'count(data.terraform.security.deny) == 0'
terraform apply tfplan
terraform output -json deployment
```

Keep `authentication_enabled = false` for the normal infrastructure exercise. For an authentication test, set all four Entra values in `terraform.tfvars` as documented in the example file; the deployment guard fails if any are missing.

Apply migrations from the repository root. The signed-in Azure identity must be the configured SQL Entra administrator:

```powershell
./scripts/migrate-azure.ps1 `
  -ResourceGroupName '<resource-group>' `
  -SqlServerName '<logical-server-name>' `
  -DatabaseName 'cloud_training' `
  -RuntimeIdentityName '<api-identity-name>' `
  -RuntimeIdentityPrincipalId '<api-identity-principal-id>' `
  -ClientIp '<your-current-public-ip>'
```

The cross-platform .NET deployment tool creates the schema and data-reader/data-writer user. The wrapper allows only one client IP temporarily and removes the firewall rule in `finally` cleanup.

## Destroy

Prefer `Azure Destroy` with `DESTROY-AZURE`. For local recovery:

```powershell
terraform plan -destroy -out destroy.tfplan
terraform apply destroy.tfplan
az resource list --resource-group rg-cloud-training --output table
```

The final inventory must be empty. The persistent resource group, state, and OIDC bootstrap remain. Azure budgets alert; they are not hard spending caps.
