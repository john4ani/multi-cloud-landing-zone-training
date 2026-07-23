using Amazon.Lambda.Core;
using CloudArchitectureTraining.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Npgsql;
using System.Globalization;
using System.Text.RegularExpressions;

[assembly: LambdaSerializer(typeof(Amazon.Lambda.Serialization.SystemTextJson.DefaultLambdaJsonSerializer))]

namespace CloudArchitectureTraining.Api.Aws;

public sealed record DatabaseMigrationRequest(string AdminPassword);

public sealed record DatabaseMigrationResult(bool Succeeded, string Message, int AppliedMigrationCount);

public sealed partial class DatabaseMigrationFunction
{
    public async Task<DatabaseMigrationResult> HandleAsync(
        DatabaseMigrationRequest request,
        ILambdaContext context)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(request.AdminPassword);

        var endpoint = RequiredEnvironmentVariable("Database__Endpoint");
        var databaseName = SafeIdentifier(RequiredEnvironmentVariable("Database__Name"));
        var adminUsername = RequiredEnvironmentVariable("Database__AdminUsername");
        var runtimeUsername = SafeIdentifier(RequiredEnvironmentVariable("Database__RuntimeUsername"));
        var rootCertificate = RequiredEnvironmentVariable("Database__RootCertificate");
        var port = int.Parse(
            RequiredEnvironmentVariable("Database__Port"),
            CultureInfo.InvariantCulture);

        var connectionString = new NpgsqlConnectionStringBuilder
        {
            Host = endpoint,
            Port = port,
            Database = databaseName,
            Username = adminUsername,
            Password = request.AdminPassword,
            SslMode = SslMode.VerifyFull,
            RootCertificate = rootCertificate,
            Timeout = 15,
            CommandTimeout = 60,
            Pooling = false
        }.ConnectionString;

        var options = new DbContextOptionsBuilder<TrainingDbContext>()
            .UseNpgsql(
                connectionString,
                postgreSql => postgreSql
                    .MigrationsAssembly(DatabaseProviders.PostgreSqlMigrationsAssembly)
                    .EnableRetryOnFailure())
            .Options;

        context.Logger.LogInformation("Applying the reviewed PostgreSQL migration history.");
        await using var dbContext = new TrainingDbContext(options);
        await dbContext.Database.MigrateAsync();

        await using var connection = new NpgsqlConnection(connectionString);
        await connection.OpenAsync();
        await using var command = connection.CreateCommand();
        var quotedRuntimeUsername = QuoteIdentifier(runtimeUsername);
        var quotedDatabaseName = QuoteIdentifier(databaseName);
        command.CommandText = $$"""
DO $migration$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '{{runtimeUsername}}') THEN
        CREATE ROLE {{quotedRuntimeUsername}} LOGIN;
    END IF;
END
$migration$;
GRANT rds_iam TO {{quotedRuntimeUsername}};
GRANT CONNECT ON DATABASE {{quotedDatabaseName}} TO {{quotedRuntimeUsername}};
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
GRANT USAGE ON SCHEMA public TO {{quotedRuntimeUsername}};
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO {{quotedRuntimeUsername}};
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO {{quotedRuntimeUsername}};
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO {{quotedRuntimeUsername}};
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT USAGE, SELECT ON SEQUENCES TO {{quotedRuntimeUsername}};
""";
        await command.ExecuteNonQueryAsync();

        var appliedMigrations = await dbContext.Database.GetAppliedMigrationsAsync();
        var count = appliedMigrations.Count();
        context.Logger.LogInformation("PostgreSQL migrations and IAM runtime-user grants completed.");
        return new DatabaseMigrationResult(true, "Database deployment completed.", count);
    }

    private static string RequiredEnvironmentVariable(string name) =>
        Environment.GetEnvironmentVariable(name) is { Length: > 0 } value
            ? value
            : throw new InvalidOperationException($"{name} is required.");

    private static string SafeIdentifier(string value) =>
        PostgreSqlIdentifierRegex().IsMatch(value)
            ? value
            : throw new InvalidOperationException("A database identifier contains unsupported characters.");

    private static string QuoteIdentifier(string value) => $"\"{value.Replace("\"", "\"\"")}\"";

    [GeneratedRegex("^[a-z_][a-z0-9_]{0,62}$", RegexOptions.CultureInvariant)]
    private static partial Regex PostgreSqlIdentifierRegex();
}
