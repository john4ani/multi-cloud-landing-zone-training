# Local development

## Prerequisites

- .NET SDK 10.0.201 or a compatible 10.0 patch
- Node.js 24.18.0
- Docker with Compose
- Terraform 1.13 or later for infrastructure formatting and validation
- OPA 1.x for local policy tests

## Start with PostgreSQL

From the repository root:

```powershell
Copy-Item .env.example .env
docker compose up --detach postgres
dotnet run --project application/backend/src/CloudArchitectureTraining.Api
npm start --prefix application/web-angular
```

Open `http://localhost:4200`. The Angular application calls the API at `http://localhost:5080`; the API uses PostgreSQL at `localhost:5432`.

The initial scaffold does not run migrations automatically. Add provider-specific EF Core migrations before the first end-to-end database run. Automatic migration at application startup is intentionally avoided because production-style deployments require a separately authorized migration step.

## Switch to SQL Server

```powershell
docker compose --profile sqlserver up --detach sqlserver
$env:Database__Provider = 'SqlServer'
$env:ConnectionStrings__TrainingDatabase = 'Server=localhost,1433;Database=cloud_training;User Id=sa;Password=Local-Only_password1!;TrustServerCertificate=True'
dotnet run --project application/backend/src/CloudArchitectureTraining.Api
```

Local passwords are examples only. Never reuse them in Azure or AWS.

## Validate

```powershell
./scripts/validate.ps1
docker compose config
```

The GitHub workflow repeats application builds, tests, Terraform formatting, and Rego tests. Cloud deployment workflows are intentionally deferred until their OIDC trust, protected environments, full workload modules, cost guards, and destroy verification are implemented.
