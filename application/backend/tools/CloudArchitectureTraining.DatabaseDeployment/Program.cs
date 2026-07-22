using CloudArchitectureTraining.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

var arguments = ParseArguments(args);
var connectionString = Environment.GetEnvironmentVariable("ConnectionStrings__TrainingDatabase")
    ?? throw new InvalidOperationException("ConnectionStrings__TrainingDatabase is required.");
var runtimeIdentityName = Required(arguments, "runtime-identity-name");
var runtimeIdentityPrincipalId = Guid.Parse(Required(arguments, "runtime-identity-principal-id"));

var options = new DbContextOptionsBuilder<TrainingDbContext>()
    .UseSqlServer(
        connectionString,
        sql => sql.MigrationsAssembly(DatabaseProviders.SqlServerMigrationsAssembly).EnableRetryOnFailure())
    .Options;

await using var context = new TrainingDbContext(options);
Console.WriteLine("Applying the reviewed SQL Server migration history...");
await context.Database.MigrateAsync();

Console.WriteLine("Granting the runtime managed identity data access...");
await context.Database.OpenConnectionAsync();
await using var command = context.Database.GetDbConnection().CreateCommand();
command.CommandText = """
DECLARE @identityName sysname = @name;
DECLARE @principalObjectId nvarchar(36) = @objectId;

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @identityName)
BEGIN
    DECLARE @createUser nvarchar(max) =
        N'CREATE USER ' + QUOTENAME(@identityName) +
        N' FROM EXTERNAL PROVIDER WITH OBJECT_ID=''' + @principalObjectId + N'''';
    EXEC sys.sp_executesql @createUser;
END;

IF IS_ROLEMEMBER(N'db_datareader', @identityName) = 0
BEGIN
    EXEC (N'ALTER ROLE db_datareader ADD MEMBER ' + QUOTENAME(@identityName));
END;

IF IS_ROLEMEMBER(N'db_datawriter', @identityName) = 0
BEGIN
    EXEC (N'ALTER ROLE db_datawriter ADD MEMBER ' + QUOTENAME(@identityName));
END;
""";

var nameParameter = command.CreateParameter();
nameParameter.ParameterName = "@name";
nameParameter.Value = runtimeIdentityName;
command.Parameters.Add(nameParameter);

var objectIdParameter = command.CreateParameter();
objectIdParameter.ParameterName = "@objectId";
objectIdParameter.Value = runtimeIdentityPrincipalId.ToString();
command.Parameters.Add(objectIdParameter);

await command.ExecuteNonQueryAsync();
Console.WriteLine("Azure SQL migration and runtime identity provisioning completed.");

static Dictionary<string, string> ParseArguments(string[] values)
{
    if (values.Length % 2 != 0)
    {
        throw new ArgumentException("Arguments must be supplied as --name value pairs.");
    }

    var result = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
    for (var index = 0; index < values.Length; index += 2)
    {
        var key = values[index];
        if (!key.StartsWith("--", StringComparison.Ordinal))
        {
            throw new ArgumentException($"Unexpected argument '{key}'.");
        }

        result[key[2..]] = values[index + 1];
    }

    return result;
}

static string Required(IReadOnlyDictionary<string, string> arguments, string name) =>
    arguments.TryGetValue(name, out var value) && !string.IsNullOrWhiteSpace(value)
        ? value
        : throw new ArgumentException($"--{name} is required.");
