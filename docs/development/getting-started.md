# Local development

## Prerequisites

- .NET SDK 10.0.201 or a compatible 10.0 patch
- Node.js 24.18.0
- Docker with Compose
- Terraform 1.13 or later for infrastructure formatting and validation
- OPA 1.x for local policy tests

## Install or update Node.js on Windows

The Angular project pins Node.js `24.18.0` in `application/web-angular/.nvmrc`. Confirm which executable Windows currently resolves:

```powershell
node --version
npm --version
where.exe node
```

### Recommended: nvm-windows

1. If you already have nvm-windows, continue to step 4.
2. Back up any user or global `.npmrc` settings you need.
3. Follow the [nvm-windows installation guidance](https://github.com/coreybutler/nvm-windows#installation--upgrades) and install it from the [official releases](https://github.com/coreybutler/nvm-windows/releases). Its maintainers recommend uninstalling a pre-existing standalone Node installation first to avoid symlink and PATH conflicts.
4. Restart PowerShell, then open it as Administrator because switching versions normally updates a Windows symlink.
5. Install and activate the project version:

```powershell
nvm version
nvm install 24.18.0 64
nvm use 24.18.0 64
nvm current
node --version
npm --version
```

Expected Node output:

```text
v24.18.0
```

If the old version remains active:

```powershell
where.exe node
nvm debug
```

Remove or reorder stale Node entries only after identifying them. A physical directory at `C:\Program Files\nodejs` can prevent nvm-windows from creating its symlink. Restart PowerShell after changing PATH or installing nvm-windows.

### No-administrator fallback: portable Node.js

Download and extract the official Node.js Windows x64 archive, then prepend it to the current terminal's PATH:

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

This PATH change lasts only for the current PowerShell process. Run the `$env:Path` assignment again in a new terminal, or install a version manager when permitted.

After either method, install the exact frontend dependencies:

```powershell
npm ci --prefix application/web-angular
```

## Start with PostgreSQL

From the repository root:

```powershell
Copy-Item .env.example .env
docker compose up --detach postgres
./scripts/migrate-local.ps1
dotnet run --project application/backend/src/CloudArchitectureTraining.Api
npm start --prefix application/web-angular
```

Open `http://localhost:4200`. The Angular application calls the API at `http://localhost:5080`; the API uses PostgreSQL at `localhost:5432`.

The migration script restores the pinned repository-local `dotnet-ef` tool and applies the PostgreSQL migration assembly. Automatic migration at application startup is intentionally avoided because production-style deployments require a separately authorized migration step.

## Run with SQL Server

Use a new API process when changing database provider. Environment variables are captured when the process starts, so an API already running with PostgreSQL will not switch providers automatically.

### 1. Stop PostgreSQL and confirm Docker is available

Stop the API with `Ctrl+C`. Angular can remain running.

```powershell
cd "C:\Work\Preparation for interviews\Cloud Architecture Training"
docker version
docker compose stop postgres
```

If `docker version` cannot reach a server, start Rancher Desktop or Docker Desktop and retry.

### 2. Start SQL Server and wait for readiness

```powershell
docker compose --profile sqlserver up --detach sqlserver
docker compose --profile sqlserver ps
```

The expected container is `cloud-architecture-training-sqlserver-1`. Its status must become `healthy`. On its first start, SQL Server upgrades and initializes system databases, so an early connection can time out even though the container has started.

The following bounded loop waits for up to two minutes:

```powershell
$sqlContainer = 'cloud-architecture-training-sqlserver-1'
$sqlStatus = $null

foreach ($attempt in 1..24) {
    $sqlStatus = docker inspect --format '{{.State.Health.Status}}' $sqlContainer 2>$null
    if ($sqlStatus -eq 'healthy') { break }
    Start-Sleep -Seconds 5
}

if ($sqlStatus -ne 'healthy') {
    docker compose --profile sqlserver logs --tail 100 sqlserver
    throw 'SQL Server did not become healthy within two minutes.'
}
```

### 3. Verify host connectivity

```powershell
$portCheck = Test-NetConnection 127.0.0.1 -Port 1433
$portCheck

if (-not $portCheck.TcpTestSucceeded) {
    throw 'SQL Server is not reachable on 127.0.0.1:1433.'
}
```

Do not run migrations or the API until this succeeds.

### 4. Apply migrations

Use `127.0.0.1` rather than `localhost` to avoid local IPv4/IPv6 resolution differences. The longer timeout also accommodates a first container start.

```powershell
$sqlConnection = 'Server=127.0.0.1,1433;Database=cloud_training;User Id=sa;Password=Local-Only_password1!;TrustServerCertificate=True;Connect Timeout=60'

./scripts/migrate-local.ps1 `
    -Provider SqlServer `
    -ConnectionString $sqlConnection
```

The command must finish with `SqlServer migrations applied successfully.` It is safe to rerun because EF Core records applied migrations in `__EFMigrationsHistory`.

### 5. Configure and start the API

Run all three commands in the same PowerShell terminal:

```powershell
$env:Database__Provider = 'SqlServer'
$env:ConnectionStrings__TrainingDatabase = $sqlConnection
dotnet run --project application/backend/src/CloudArchitectureTraining.Api
```

If you launch through Visual Studio, Rider, VS Code, or another terminal, configure `Database__Provider` and `ConnectionStrings__TrainingDatabase` in that launch environment. Variables set in one PowerShell process are not inherited by an IDE or an already-running process.

### 6. Verify the complete path

From another terminal:

```powershell
Invoke-RestMethod http://localhost:5080/health
Invoke-RestMethod http://localhost:5080/api/topics
```

The second call exercises SQL Server connectivity and the migrated `interview_topics` table. Then open `http://localhost:4200`, add a topic, refresh the page, and confirm that it remains present.

### 7. Stop the environment

Stop the API with `Ctrl+C`, then run:

```powershell
docker compose --profile sqlserver stop sqlserver
```

### SQL Server troubleshooting

- **`No such container` or an empty `docker compose ps`:** run `docker compose --profile sqlserver up --detach sqlserver` again.
- **TCP timeout/error 258:** wait for `healthy`, run `Test-NetConnection`, and inspect `docker compose --profile sqlserver logs --tail 100 sqlserver`.
- **Port 1433 is already occupied:** run `Get-NetTCPConnection -LocalPort 1433 -State Listen` and stop or reconfigure the conflicting local SQL Server service before starting Compose.
- **Login failed for `sa`:** ensure the password in `$sqlConnection` matches `SQLSERVER_SA_PASSWORD` in `.env`. The checked-in example uses `Local-Only_password1!`.
- **`Invalid object name 'interview_topics'`:** apply the SQL Server migration again and confirm it reports success.
- **The API still uses PostgreSQL:** stop it completely, set both environment variables, and start a new API process from the same terminal.

Local passwords are examples only. Never reuse them in Azure or AWS.

## Add a schema change

Change the EF Core model first, then generate the same named migration in both provider histories:

```powershell
./scripts/add-migration.ps1 -Name AddExampleField
```

Review both generated migrations. PostgreSQL and SQL Server types, defaults, indexes, and SQL operations can differ. Commit both histories in the same change and verify that each can produce an idempotent script.

## Validate

```powershell
./scripts/validate.ps1
docker compose config
```

The GitHub validation workflow repeats application builds, tests, Terraform validation, Rego tests, workflow hardening, and security scanning. Azure and AWS plan/deploy/destroy workflows are implemented but require the one-time OIDC and protected-environment setup in the [Azure CI/CD guide](azure-cicd.md) and [AWS CI/CD guide](aws-cicd.md). Local authentication is disabled by default; see the [authentication guide](authentication.md) for provider setup and deployment validation.
