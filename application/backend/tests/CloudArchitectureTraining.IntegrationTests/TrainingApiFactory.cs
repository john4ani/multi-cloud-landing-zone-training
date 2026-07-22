using CloudArchitectureTraining.Infrastructure.Persistence;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;

namespace CloudArchitectureTraining.IntegrationTests;

public sealed class TrainingApiFactory : WebApplicationFactory<Program>
{
    private readonly string _databaseName = $"cloud-training-{Guid.NewGuid()}";

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.ConfigureServices(services =>
        {
            services.RemoveAll<TrainingDbContext>();
            services.RemoveAll<DbContextOptions<TrainingDbContext>>();
            services.RemoveAll<IDbContextOptionsConfiguration<TrainingDbContext>>();

            services.AddDbContext<TrainingDbContext>(options =>
                options.UseInMemoryDatabase(_databaseName));
        });
    }
}
