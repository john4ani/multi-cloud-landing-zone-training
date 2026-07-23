using Amazon.RDS.Util;
using CloudArchitectureTraining.Application.InterviewTopics;
using CloudArchitectureTraining.Infrastructure.Persistence;
using CloudArchitectureTraining.Infrastructure.Repositories;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Npgsql;

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

        var useAwsIamAuthentication =
            bool.TryParse(configuration["Database:UseAwsIamAuthentication"], out var configuredAwsIam) &&
            configuredAwsIam;

        if (provider.Equals(DatabaseProviders.PostgreSql, StringComparison.OrdinalIgnoreCase) &&
            useAwsIamAuthentication)
        {
            services.AddSingleton(_ =>
            {
                var dataSourceBuilder = new NpgsqlDataSourceBuilder(connectionString);
                dataSourceBuilder.UsePeriodicPasswordProvider(
                    (settings, _) => ValueTask.FromResult(RDSAuthTokenGenerator.GenerateAuthToken(
                        settings.Host,
                        settings.Port,
                        settings.Username)),
                    TimeSpan.FromMinutes(10),
                    TimeSpan.FromSeconds(10));
                return dataSourceBuilder.Build();
            });

            services.AddDbContext<TrainingDbContext>((serviceProvider, options) =>
                options.UseNpgsql(
                    serviceProvider.GetRequiredService<NpgsqlDataSource>(),
                    postgreSql => postgreSql
                        .MigrationsAssembly(DatabaseProviders.PostgreSqlMigrationsAssembly)
                        .EnableRetryOnFailure()));
        }
        else
        {
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
        }

        services.AddScoped<IInterviewTopicRepository, InterviewTopicRepository>();
        return services;
    }
}
