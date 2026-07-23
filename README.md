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
9. [Database migration workflow](docs/development/database-migrations.md)
10. [Policy-as-Code design](docs/security/policy-as-code.md)
11. [Azure CI/CD setup and operation](docs/development/azure-cicd.md)
12. [AWS CI/CD setup and operation](docs/development/aws-cicd.md)
13. [AWS manual deployment runbook](docs/development/deploy-aws.md)

## Run locally

### Prerequisites

- .NET SDK 10.0.201 or a compatible .NET 10 SDK
- Node.js 24.18.0
- Docker with Docker Compose

#### Install or switch to Node.js 24.18.0 on Windows

Check the active version and executable first:

```powershell
node --version
where.exe node
```

The recommended option is [nvm-windows](https://github.com/coreybutler/nvm-windows/releases). If it is already installed, open PowerShell as Administrator and run:

```powershell
nvm install 24.18.0 64
nvm use 24.18.0 64
node --version
npm --version
```

`node --version` must return `v24.18.0`. Restart PowerShell after installing nvm-windows. If `nvm use` succeeds but an older Node version is still reported, run `where.exe node` and `nvm debug` to find a PATH conflict. The nvm-windows project recommends removing a pre-existing standalone Node installation before installing nvm-windows because its physical installation directory can block the nvm symlink.

If you cannot install software or obtain administrator access, use the official portable ZIP for the current PowerShell session:

```powershell
$nodeVersion = '24.18.0'
$nodeTools = Join-Path $env:LOCALAPPDATA 'CloudArchitectureTraining\Node'
$nodeArchive = Join-Path $env:TEMP "node-v$nodeVersion-win-x64.zip"
$nodeDirectory = Join-Path $nodeTools "node-v$nodeVersion-win-x64"

New-Item -ItemType Directory -Force -Path $nodeTools | Out-Null
Invoke-WebRequest `
    -Uri "https://nodejs.org/download/release/v$nodeVersion/node-v$nodeVersion-win-x64.zip" `
    -OutFile $nodeArchive
Expand-Archive -LiteralPath $nodeArchive -DestinationPath $nodeTools -Force
$env:Path = "$nodeDirectory;$env:Path"

node --version
npm --version
```

The portable PATH change applies only to the current PowerShell session. See the [local development guide](docs/development/getting-started.md#install-or-update-nodejs-on-windows) for troubleshooting and upgrade details.

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

### 2. Apply the PostgreSQL migration

```powershell
./scripts/migrate-local.ps1
```

This restores the repository-local EF Core tool and applies only the PostgreSQL migration history.

### 3. Start the .NET API

Open a second PowerShell terminal in the repository root:

```powershell
dotnet run --project application/backend/src/CloudArchitectureTraining.Api
```

The API listens on `http://localhost:5080`. Check its health endpoint at `http://localhost:5080/health`.

### 4. Start Angular

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

### Run the complete application with SQL Server

Follow these steps from the beginning when switching from PostgreSQL. Do not reuse an API process that was started with PostgreSQL settings.

#### 1. Stop the existing API and PostgreSQL

Stop the API with `Ctrl+C`. Angular may remain running. From the repository root, stop PostgreSQL to free memory:

```powershell
docker compose stop postgres
```

Ensure Rancher Desktop or Docker Desktop is running before continuing.

#### 2. Start SQL Server

```powershell
docker compose --profile sqlserver up --detach sqlserver
docker compose --profile sqlserver ps
```

The first SQL Server start can take longer while its system databases are initialized. Repeat the `ps` command until `cloud-architecture-training-sqlserver-1` reports `healthy`.

#### 3. Confirm that port 1433 is reachable

```powershell
Test-NetConnection 127.0.0.1 -Port 1433
```

Continue only when `TcpTestSucceeded` is `True`. If it is false, inspect the container before running the API:

```powershell
docker compose --profile sqlserver ps
docker compose --profile sqlserver logs --tail 100 sqlserver
```

#### 4. Apply the SQL Server migration

Define the connection string once and pass the same value to migration and runtime commands:

```powershell
$sqlConnection = 'Server=127.0.0.1,1433;Database=cloud_training;User Id=sa;Password=Local-Only_password1!;TrustServerCertificate=True;Connect Timeout=60'

./scripts/migrate-local.ps1 `
    -Provider SqlServer `
    -ConnectionString $sqlConnection
```

Wait for `SqlServer migrations applied successfully.` before continuing.

#### 5. Start the API with SQL Server

In the same PowerShell terminal where `$sqlConnection` was defined:

```powershell
$env:Database__Provider = 'SqlServer'
$env:ConnectionStrings__TrainingDatabase = $sqlConnection

dotnet run --project application/backend/src/CloudArchitectureTraining.Api
```

Environment variables apply only to the process started from that terminal. If the API is launched from an IDE or another terminal, configure the same two values there or use this command instead.

#### 6. Verify API and database access

Open another PowerShell terminal:

```powershell
Invoke-RestMethod http://localhost:5080/health
Invoke-RestMethod http://localhost:5080/api/topics
```

The health request confirms the API is running. The topics request confirms that the API can connect to SQL Server and query the migrated table. Open `http://localhost:4200` to use the Angular application.

#### 7. Stop SQL Server

After stopping the API with `Ctrl+C`:

```powershell
docker compose --profile sqlserver stop sqlserver
```

The password above is for local training only. Never reuse it in Azure or AWS. Database migrations are explicit: application startup never changes a schema. PostgreSQL and SQL Server have independent migration histories so provider-specific SQL can evolve safely without coupling the deployments.

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

The application and protected Azure/AWS Terraform delivery lanes are implemented. Cloud workload creation remains disabled by default. Real deployments require each cloud's state/OIDC bootstrap, protected GitHub environments, and explicit opt-in. See the [implementation status](docs/development/implementation-status.md), [Azure CI/CD guide](docs/development/azure-cicd.md), [AWS CI/CD guide](docs/development/aws-cicd.md), and the cloud deployment runbooks.

## Documentation principle

Documentation is part of the product. A change is not complete when it changes architecture, behavior, security, deployment, cost, operations, or interfaces without updating the relevant documentation in the same change.
