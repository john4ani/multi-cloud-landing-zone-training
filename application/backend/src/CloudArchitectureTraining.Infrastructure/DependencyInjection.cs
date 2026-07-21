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
        var provider = configuration["Database:Provider"] ?? "PostgreSql";
        var connectionString = configuration.GetConnectionString("TrainingDatabase")
            ?? throw new InvalidOperationException("ConnectionStrings:TrainingDatabase is required.");

        services.AddDbContext<TrainingDbContext>(options =>
        {
            if (provider.Equals("SqlServer", StringComparison.OrdinalIgnoreCase))
            {
                options.UseSqlServer(connectionString);
            }
            else if (provider.Equals("PostgreSql", StringComparison.OrdinalIgnoreCase))
            {
                options.UseNpgsql(connectionString);
            }
            else
            {
                throw new InvalidOperationException(
                    $"Unsupported database provider '{provider}'. Use SqlServer or PostgreSql.");
            }
        });

        services.AddScoped<IInterviewTopicRepository, InterviewTopicRepository>();
        return services;
    }
}
