# Database migration workflow

The application shares one EF Core model while PostgreSQL and SQL Server keep independent migration assemblies:

- `CloudArchitectureTraining.Migrations.PostgreSql`
- `CloudArchitectureTraining.Migrations.SqlServer`

At runtime, `Database:Provider` selects both the EF Core provider and its matching migration assembly. The API references both assemblies so they are included in build and publish output.

## Local application

Start the selected database and run `scripts/migrate-local.ps1` before starting the API. The script accepts `PostgreSql` (default) or `SqlServer` and an optional connection string.

## Schema changes

Run `scripts/add-migration.ps1 -Name <MigrationName>`. It creates the named migration in both histories. Review the generated files instead of assuming their SQL is equivalent.

## Delivery controls

- Application startup never applies migrations.
- CI generates idempotent scripts for both providers without connecting to a database.
- A deployment migration job must use a separate, short-lived identity with schema-change permission.
- The runtime identity receives data access but not schema-owner permission.
- Backups and restore readiness must be verified before destructive migrations.
- Roll-forward is preferred; a down migration is not a substitute for tested data recovery.

## Azure controlled migration

The Azure workload uses `scripts/migrate-azure.ps1` after Terraform apply. The script temporarily permits exactly one migration-runner IP, applies the SQL Server history with the signed-in Entra identity, creates the runtime managed-identity database user with data-reader/data-writer roles, and removes the firewall rule in guaranteed cleanup. See the [Azure deployment runbook](deploy-azure.md).
