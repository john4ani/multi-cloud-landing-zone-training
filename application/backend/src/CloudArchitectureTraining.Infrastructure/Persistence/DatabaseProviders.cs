namespace CloudArchitectureTraining.Infrastructure.Persistence;

public static class DatabaseProviders
{
    public const string PostgreSql = "PostgreSql";
    public const string SqlServer = "SqlServer";

    public const string PostgreSqlMigrationsAssembly =
        "CloudArchitectureTraining.Migrations.PostgreSql";

    public const string SqlServerMigrationsAssembly =
        "CloudArchitectureTraining.Migrations.SqlServer";
}
