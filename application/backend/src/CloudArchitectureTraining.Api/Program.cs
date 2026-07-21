using CloudArchitectureTraining.Application.InterviewTopics;
using CloudArchitectureTraining.Infrastructure;
using Microsoft.AspNetCore.Authentication.JwtBearer;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddProblemDetails();
builder.Services.AddHealthChecks();
builder.Services.AddScoped<InterviewTopicService>();
builder.Services.AddTrainingInfrastructure(builder.Configuration);
builder.Services.AddCors(options => options.AddDefaultPolicy(policy => policy
    .WithOrigins(builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>() ?? ["http://localhost:4200"])
    .AllowAnyHeader()
    .AllowAnyMethod()));

var authenticationEnabled = builder.Configuration.GetValue("Authentication:Enabled", false);
if (authenticationEnabled)
{
    builder.Services
        .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
        .AddJwtBearer(options =>
        {
            options.Authority = builder.Configuration["Authentication:Authority"];
            options.Audience = builder.Configuration["Authentication:Audience"];
            options.RequireHttpsMetadata = true;
        });
    builder.Services.AddAuthorization();
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
if (authenticationEnabled) topics.RequireAuthorization();

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

public partial class Program;
