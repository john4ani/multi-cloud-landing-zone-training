# ADR-0008: Use provider-specific EF Core migration assemblies

- Status: Accepted
- Date: 2026-07-21

## Context

The application must run against Azure SQL in Azure and PostgreSQL in AWS. A common EF Core model supports application portability, but generated column types, SQL syntax, annotations, defaults, and operational behavior differ between providers. A single migration history would conceal those differences and can generate invalid or unsafe SQL for one target.

Application startup must not require schema-owner permission. Cloud deployments also need a reviewable migration artifact and a separately authorized migration step.

## Decision

- Keep the domain model and `TrainingDbContext` shared.
- Maintain separate migration assemblies for PostgreSQL and SQL Server.
- Select the provider and matching migration assembly through `Database:Provider`.
- Generate the same logical schema change for both providers in one repository change.
- Review and test both generated migration histories.
- Produce idempotent scripts in CI for review evidence.
- Apply migrations explicitly before application deployment with a dedicated migration identity.
- Never apply migrations automatically during API startup.

## Consequences

- Provider differences are visible and independently reviewable.
- The application layer remains cloud-neutral.
- Each schema change produces two migration artifacts and requires dual-provider validation.
- Deployment automation must coordinate schema compatibility and application rollout.

## Alternatives considered

### One shared migration assembly

Rejected because migrations are provider-specific even when the EF Core model is shared.

### Create the schema automatically at startup

Rejected because it gives the runtime excessive privileges, weakens review, and makes failures harder to control.

### Maintain separate domain models

Rejected because it would duplicate application behavior and undermine the portability objective.

## Validation

- Both migration projects compile with warnings treated as errors.
- Both providers generate an idempotent initial migration script.
- PostgreSQL applies its migration and passes an API CRUD smoke test.
- SQL Server migration execution is exercised when the local SQL Server container is available.
