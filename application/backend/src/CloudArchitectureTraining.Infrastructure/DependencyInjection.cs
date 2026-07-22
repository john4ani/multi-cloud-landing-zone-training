using CloudArchitectureTraining.Application.InterviewTopics;
using CloudArchitectureTraining.Infrastructure.Persistence;
using CloudArchitectureTraining.Infrastructure.Repositories;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace CloudArchitectureTraining.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddTrainingInfrastructure(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        var provider = configuration["Database:Provider"] ?? DatabaseProviders.PostgreSql;
        var connectionString = configuration.GetConnectionString("TrainingDatabase")
            ?? throw new InvalidOperationException("ConnectionStrings:TrainingDatabase is required.");

        services.AddDbContext<TrainingDbContext>(options =>
        {
            if (provider.Equals(DatabaseProviders.SqlServer, StringComparison.OrdinalIgnoreCase))
            {
                options.UseSqlServer(
                    connectionString,
                    sqlServer => sqlServer
                        .MigrationsAssembly(DatabaseProviders.SqlServerMigrationsAssembly)
                        .EnableRetryOnFailure());
            }
            else if (provider.Equals(DatabaseProviders.PostgreSql, StringComparison.OrdinalIgnoreCase))
            {
                options.UseNpgsql(
                    connectionString,
                    postgreSql => postgreSql
                        .MigrationsAssembly(DatabaseProviders.PostgreSqlMigrationsAssembly)
                        .EnableRetryOnFailure());
            }
            else
            {
                throw new InvalidOperationException(
                    $"Unsupported database provider '{provider}'. " +
                    $"Use {DatabaseProviders.SqlServer} or {DatabaseProviders.PostgreSql}.");
            }
        });

        services.AddScoped<IInterviewTopicRepository, InterviewTopicRepository>();
        return services;
    }
}
