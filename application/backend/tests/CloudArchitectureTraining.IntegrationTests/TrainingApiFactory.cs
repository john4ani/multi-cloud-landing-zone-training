using System.Net.Http.Headers;
using System.Security.Claims;
using CloudArchitectureTraining.Infrastructure.Persistence;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.JsonWebTokens;
using Microsoft.IdentityModel.Tokens;

namespace CloudArchitectureTraining.IntegrationTests;

public sealed class TrainingApiFactory : WebApplicationFactory<Program>
{
    public const string Issuer = "https://test.identity.example";
    public const string Audience = "cloud-training-test-api";
    private const string SigningKey = "local-integration-test-signing-key-32-bytes-minimum";
    private readonly string _databaseName = $"cloud-training-{Guid.NewGuid()}";

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseSetting("Authentication:Enabled", "true");
        builder.UseSetting("Authentication:Provider", "Cognito");
        builder.UseSetting("Authentication:Authority", Issuer);
        builder.UseSetting("Authentication:Audience", Audience);
        builder.UseSetting("Authentication:RoleClaimType", "roles");

        builder.ConfigureServices(services =>
        {
            services.RemoveAll<TrainingDbContext>();
            services.RemoveAll<DbContextOptions<TrainingDbContext>>();
            services.RemoveAll<IDbContextOptionsConfiguration<TrainingDbContext>>();

            services.AddDbContext<TrainingDbContext>(options =>
                options.UseInMemoryDatabase(_databaseName));
            services.AddSingleton<IPostConfigureOptions<JwtBearerOptions>, TestJwtBearerPostConfigure>();
        });
    }

    public HttpClient CreateAuthenticatedClient(
        string subject,
        params string[] roles)
    {
        var client = CreateClient();
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", CreateToken(subject, roles));
        return client;
    }

    private static string CreateToken(string subject, IEnumerable<string> roles)
    {
        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, subject),
            new("name", subject),
            new("client_id", Audience),
            new("token_use", "access"),
        };
        claims.AddRange(roles.Select(role => new Claim("roles", role)));

        return new JsonWebTokenHandler().CreateToken(new SecurityTokenDescriptor
        {
            Audience = Audience,
            Expires = DateTime.UtcNow.AddMinutes(10),
            Issuer = Issuer,
            SigningCredentials = new(
                new SymmetricSecurityKey(System.Text.Encoding.UTF8.GetBytes(SigningKey)),
                SecurityAlgorithms.HmacSha256),
            Subject = new ClaimsIdentity(claims),
        });
    }

    private sealed class TestJwtBearerPostConfigure : IPostConfigureOptions<JwtBearerOptions>
    {
        public void PostConfigure(string? name, JwtBearerOptions options)
        {
            if (!string.Equals(name, JwtBearerDefaults.AuthenticationScheme, StringComparison.Ordinal))
            {
                return;
            }

            options.Authority = null;
            options.MetadataAddress = null!;
            options.ConfigurationManager = null!;
            options.TokenValidationParameters = new()
            {
                ClockSkew = TimeSpan.Zero,
                NameClaimType = "name",
                RoleClaimType = "roles",
                ValidAlgorithms = [SecurityAlgorithms.HmacSha256],
                ValidAudience = Audience,
                ValidIssuer = Issuer,
                IssuerSigningKey =
                    new SymmetricSecurityKey(System.Text.Encoding.UTF8.GetBytes(SigningKey)),
                ValidateAudience = true,
                ValidateIssuer = true,
                ValidateIssuerSigningKey = true,
                ValidateLifetime = true,
            };
        }
    }
}
