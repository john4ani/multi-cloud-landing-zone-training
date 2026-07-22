namespace CloudArchitectureTraining.IntegrationTests;

public sealed class HealthEndpointTests : IClassFixture<TrainingApiFactory>
{
    private readonly HttpClient _client;

    public HealthEndpointTests(TrainingApiFactory factory) =>
        _client = factory.CreateClient(new() { AllowAutoRedirect = false });

    [Fact]
    public async Task HealthEndpointReturnsSuccess()
    {
        var response = await _client.GetAsync("/health");
        response.EnsureSuccessStatusCode();
    }
}
