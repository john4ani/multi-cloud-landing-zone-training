# Multi-Cloud Landing Zone Training

This repository is a learning implementation of an extensible, workload-focused landing zone for Microsoft Azure and AWS.

The reference workload uses Angular 22, ASP.NET Core on .NET 10, Azure SQL in Azure, PostgreSQL on AWS, Terraform, Policy as Code, and Documentation as Code.

## Start here

1. [Project requirements](docs/requirements.md)
2. [Architecture overview](docs/architecture/overview.md)
3. [Azure deployment architecture](docs/architecture/azure-deployment.md)
4. [AWS deployment architecture](docs/architecture/aws-deployment.md)
5. [Delivery and Terraform state control plane](docs/architecture/delivery-control-plane.md)
6. [Architecture Decision Records](docs/adrs/README.md)
7. [Local development](docs/development/getting-started.md)
8. [Implementation status](docs/development/implementation-status.md)
9. [Policy-as-Code design](docs/security/policy-as-code.md)

## Run locally

### Prerequisites

- .NET SDK 10.0.201 or a compatible .NET 10 SDK
- Node.js 24.18.0
- Docker with Docker Compose

Open PowerShell in the repository root:

```powershell
cd "C:\Work\Preparation for interviews\Cloud Architecture Training"
```

### 1. Start PostgreSQL

```powershell
Copy-Item .env.example .env
docker compose up --detach postgres
docker compose ps
```

PostgreSQL listens on `localhost:5432`.

### 2. Start the .NET API

Open a second PowerShell terminal in the repository root:

```powershell
dotnet run --project application/backend/src/CloudArchitectureTraining.Api
```

The API listens on `http://localhost:5080`. Check its health endpoint at `http://localhost:5080/health`.

### 3. Start Angular

Open a third PowerShell terminal in the repository root:

```powershell
npm ci --prefix application/web-angular
npm start --prefix application/web-angular
```

Open `http://localhost:4200` in a browser. Angular calls the API at `http://localhost:5080`.

### Stop the local environment

Stop the API and Angular processes with `Ctrl+C`, then stop PostgreSQL:

```powershell
docker compose down
```

### Use SQL Server instead

```powershell
docker compose --profile sqlserver up --detach sqlserver
$env:Database__Provider = 'SqlServer'
$env:ConnectionStrings__TrainingDatabase = 'Server=localhost,1433;Database=cloud_training;User Id=sa;Password=Local-Only_password1!;TrustServerCertificate=True'
dotnet run --project application/backend/src/CloudArchitectureTraining.Api
```

The passwords in `.env.example` are for local training only. Never reuse them in Azure or AWS.

> **Current limitation:** the application processes and health endpoint run, but the initial scaffold does not yet create the database schema. Interview-topic CRUD persistence requires the provider-specific EF Core migrations listed in the [next implementation slice](docs/development/implementation-status.md). Automatic production database migration is intentionally avoided.

### Run validation

```powershell
./scripts/validate.ps1
docker compose config
```

For more detail, see the [local development guide](docs/development/getting-started.md).

## Repository layout

- `application/backend`: .NET 10 API, portable domain/application layers, EF Core providers, and tests.
- `application/web-angular`: Angular browser application.
- `infrastructure`: separate Azure/AWS bootstrap, environment, and reusable module roots.
- `policies`: Rego rules and tests for Terraform plan JSON.
- `docs`: architecture, ADRs, security material, requirements, and development guides.
- `.github`: validation automation, dependency updates, and protected-file ownership.

## Current status

The first application and delivery scaffold is implemented. Cloud workload creation remains disabled by default and the full private API/database stacks are the next implementation slice. See the [implementation status](docs/development/implementation-status.md) for an exact boundary between implemented resources and the target diagrams.

## Documentation principle

Documentation is part of the product. A change is not complete when it changes architecture, behavior, security, deployment, cost, operations, or interfaces without updating the relevant documentation in the same change.
