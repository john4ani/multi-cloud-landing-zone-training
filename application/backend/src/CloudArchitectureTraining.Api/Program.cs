using Amazon.Lambda.AspNetCoreServer.Hosting;
using CloudArchitectureTraining.Api.Security;
using CloudArchitectureTraining.Application.InterviewTopics;
using CloudArchitectureTraining.Application.Security;
using CloudArchitectureTraining.Infrastructure;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text.Json.Serialization;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddProblemDetails();
builder.Services.AddAWSLambdaHosting(LambdaEventSource.HttpApi);
builder.Services.AddHealthChecks();
builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<ICurrentUser, HttpContextCurrentUser>();
builder.Services.AddScoped<InterviewTopicService>();
builder.Services.AddTrainingInfrastructure(builder.Configuration);
builder.Services.ConfigureHttpJsonOptions(options =>
    options.SerializerOptions.Converters.Add(new JsonStringEnumConverter()));
builder.Services.AddCors(options => options.AddDefaultPolicy(policy => policy
    .WithOrigins(builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>() ?? ["http://localhost:4200"])
    .AllowAnyHeader()
    .AllowAnyMethod()));

var authenticationEnabled = builder.Configuration.GetValue("Authentication:Enabled", false);
if (authenticationEnabled)
{
    var authority = GetRequiredAuthenticationSetting(builder.Configuration, "Authority");
    var audience = GetRequiredAuthenticationSetting(builder.Configuration, "Audience");
    var provider = NormalizeAuthenticationProvider(
        GetRequiredAuthenticationSetting(builder.Configuration, "Provider"));
    var roleClaimType = GetRequiredAuthenticationSetting(builder.Configuration, "RoleClaimType");

    builder.Services
        .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
        .AddJwtBearer(options =>
        {
            options.Authority = authority;
            options.Audience = audience;
            options.MapInboundClaims = false;
            options.RequireHttpsMetadata = true;
            options.TokenValidationParameters = new()
            {
                ClockSkew = TimeSpan.FromMinutes(2),
                NameClaimType = "name",
                RoleClaimType = roleClaimType,
                ValidAlgorithms = [SecurityAlgorithms.RsaSha256],
                ValidateAudience = !provider.Equals("Cognito", StringComparison.OrdinalIgnoreCase),
            };

            options.Events = new()
            {
                OnTokenValidated = context =>
                {
                    if (provider == "Cognito")
                    {
                        var clientId = context.Principal?.FindFirst("client_id")?.Value;
                        var tokenUse = context.Principal?.FindFirst("token_use")?.Value;
                        var subject = context.Principal?.FindFirst("sub")?.Value;
                        if (!string.Equals(clientId, audience, StringComparison.Ordinal) ||
                            !string.Equals(tokenUse, "access", StringComparison.Ordinal) ||
                            string.IsNullOrWhiteSpace(subject))
                        {
                            context.Fail("The Cognito access token is missing required claims.");
                        }
                    }
                    else
                    {
                        var tenantId = context.Principal?.FindFirst("tid")?.Value;
                        var objectId = context.Principal?.FindFirst("oid")?.Value;
                        if (string.IsNullOrWhiteSpace(tenantId) ||
                            string.IsNullOrWhiteSpace(objectId))
                        {
                            context.Fail("The Entra access token is missing required claims.");
                        }
                    }

                    return Task.CompletedTask;
                },
            };
        });
    builder.Services.AddAuthorization(options =>
        options.AddPolicy(
            ApplicationRoles.UserOrAdministratorPolicy,
            policy => policy.RequireRole(ApplicationRoles.User, ApplicationRoles.Administrator)));
}

var app = builder.Build();

app.UseExceptionHandler();
if (!app.Environment.IsDevelopment()) app.UseHttpsRedirection();
app.UseCors();
if (authenticationEnabled)
{
    app.UseAuthentication();
    app.UseAuthorization();
}

app.MapHealthChecks("/health");

var topics = app.MapGroup("/api/topics");
if (authenticationEnabled)
{
    topics.RequireAuthorization(ApplicationRoles.UserOrAdministratorPolicy);
}

topics.MapGet("/", async (InterviewTopicService service, CancellationToken ct) =>
    Results.Ok(await service.ListAsync(ct)));

topics.MapGet("/{id:guid}", async (Guid id, InterviewTopicService service, CancellationToken ct) =>
    await service.GetAsync(id, ct) is { } topic ? Results.Ok(topic) : Results.NotFound());

topics.MapPost("/", async (SaveInterviewTopicRequest request, InterviewTopicService service, CancellationToken ct) =>
{
    var topic = await service.CreateAsync(request, ct);
    return Results.Created($"/api/topics/{topic.Id}", topic);
});

topics.MapPut("/{id:guid}", async (
    Guid id,
    SaveInterviewTopicRequest request,
    InterviewTopicService service,
    CancellationToken ct) =>
    await service.UpdateAsync(id, request, ct) is { } topic ? Results.Ok(topic) : Results.NotFound());

topics.MapDelete("/{id:guid}", async (Guid id, InterviewTopicService service, CancellationToken ct) =>
    await service.DeleteAsync(id, ct) ? Results.NoContent() : Results.NotFound());

app.Run();

static string GetRequiredAuthenticationSetting(IConfiguration configuration, string name)
{
    var value = configuration[$"Authentication:{name}"];
    return !string.IsNullOrWhiteSpace(value)
        ? value
        : throw new InvalidOperationException($"Authentication:{name} is required when authentication is enabled.");
}

static string NormalizeAuthenticationProvider(string provider) =>
    provider.Equals("Entra", StringComparison.OrdinalIgnoreCase)
        ? "Entra"
        : provider.Equals("Cognito", StringComparison.OrdinalIgnoreCase)
            ? "Cognito"
            : throw new InvalidOperationException(
                "Authentication:Provider must be Entra or Cognito when authentication is enabled.");

public partial class Program;
