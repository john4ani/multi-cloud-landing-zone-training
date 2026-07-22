# Azure CI/CD setup and operation

The Azure delivery lane uses GitHub Actions, short-lived Azure OIDC tokens, separate plan/apply identities, protected environments, Policy as Code, an immutable image digest, an exact saved Terraform plan, database migrations, frontend deployment, smoke tests, and guarded destruction.

## One-time Azure bootstrap

Run the bootstrap locally with an Azure identity allowed to create resource groups, managed identities, federated credentials, and role assignments:

```powershell
cd infrastructure/bootstrap/azure
terraform init
terraform apply `
  -var='configure_github_oidc=true' `
  -var='github_repository=<github-owner>/<repository-name>'
terraform output
```

The bootstrap creates the persistent workload resource group, versioned Blob state, and two identities:

- Plan: Reader on `rg-cloud-training` and Storage Blob Data Reader on the state account.
- Apply: Contributor on `rg-cloud-training` and Storage Blob Data Contributor on the state account.

Bootstrap resources survive the workload destroy workflow by design.

## GitHub configuration

Create these repository variables from the bootstrap output and Azure account details:

| Variable | Value |
|---|---|
| `AZURE_TENANT_ID` | `tenant_id` |
| `AZURE_SUBSCRIPTION_ID` | `subscription_id` |
| `AZURE_PLAN_CLIENT_ID` | `github_plan_client_id` |
| `AZURE_APPLY_CLIENT_ID` | `github_apply_client_id` |
| `AZURE_APPLY_PRINCIPAL_ID` | `github_apply_principal_id` |
| `AZURE_TFSTATE_RESOURCE_GROUP` | `state_resource_group_name` |
| `AZURE_TFSTATE_STORAGE_ACCOUNT` | `storage_account_name` |
| `AZURE_TFSTATE_CONTAINER` | `container_name` |

Create two GitHub environments:

1. `azure-training-plan` protects creation of the deployable, saved plan.
2. `azure-training` protects application of that plan and destruction.

Configure required reviewers on both. Add the same environment secret named `AZURE_SQL_ADMIN_PASSWORD` to both environments. Use a unique value of at least 16 characters. It is a database bootstrap credential, not an Azure service-principal secret.

The API image is published to GitHub Container Registry. Make the repository's `api` package public so Azure Container Apps can pull it without a stored registry credential. On the first run, let the `build` job publish the package, change its visibility before approving `azure-training-plan`, and then continue the deployment. Later runs need no visibility change. The application must not contain secrets.

## Workflows

- `Validate` runs on pull requests and `main`: formatting, .NET tests, both migration histories, Angular tests/build, Terraform validation, Rego tests, workflow hardening, and Trivy scanning.
- `Azure Plan` creates a read-only speculative plan for same-repository pull requests. It never uploads the binary plan or exposes apply permissions.
- `Azure Deploy` is manually dispatched from `main`. Enter `DEPLOY-AZURE`, an expiry date, and an optional budget email. It builds and scans the exact commit, publishes an immutable image, creates a protected exact plan, verifies its checksum, applies it through the apply identity, migrates Azure SQL, deploys Angular, runs CRUD smoke tests, and rotates the temporary Static Web Apps token.
- `Azure Destroy` is manually dispatched from `main`. Enter `DESTROY-AZURE`; the protected apply identity creates and applies a checked destroy plan, then verifies that the workload resource group is empty.

The Azure workflows share one concurrency group, so deploy and destroy cannot modify the same Terraform state simultaneously. Fork pull requests do not receive an Azure token.

## Required GitHub controls

- Require `Validate` and `Azure Plan / plan` before merging Azure changes.
- Require CODEOWNERS review for workflows, policies, infrastructure, and ADRs.
- Do not bypass the environment approvals for training deployments.
- Keep Actions restricted to the pinned actions used by this repository.
- Retain exact-plan artifacts for one day only and never upload Terraform state.

## Expected retained resources

After `Azure Destroy`, the state resource group, state storage, workload resource group, GitHub managed identities, federated credentials, and role assignments remain. The workload resource group must contain zero workload resources. Delete bootstrap resources manually only when the entire exercise is retired and the state is no longer needed.
