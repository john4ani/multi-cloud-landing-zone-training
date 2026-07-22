using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;
using CloudArchitectureTraining.Application.InterviewTopics;
using CloudArchitectureTraining.Domain.InterviewTopics;

namespace CloudArchitectureTraining.IntegrationTests;

public sealed class InterviewTopicEndpointTests : IClassFixture<TrainingApiFactory>
{
    private static readonly JsonSerializerOptions JsonOptions = CreateJsonOptions();
    private readonly HttpClient _client;

    public InterviewTopicEndpointTests(TrainingApiFactory factory) => _client = factory.CreateClient();

    [Fact]
    public async Task CrudRoundTripUsesStringStatusValues()
    {
        var createResponse = await _client.PostAsJsonAsync(
            "/api/topics",
            new SaveInterviewTopicRequest(
                "Workload identity",
                "Portable",
                "Compare managed identity and IAM roles.",
                TopicStatus.InProgress));
        createResponse.EnsureSuccessStatusCode();

        var createdJson = await createResponse.Content.ReadAsStringAsync();
        Assert.Contains("\"status\":\"InProgress\"", createdJson);

        var created = await createResponse.Content.ReadFromJsonAsync<InterviewTopicDto>(JsonOptions);
        Assert.NotNull(created);

        var updateResponse = await _client.PutAsJsonAsync(
            $"/api/topics/{created.Id}",
            new SaveInterviewTopicRequest(
                created.Title,
                created.Cloud,
                created.Notes,
                TopicStatus.Completed));
        updateResponse.EnsureSuccessStatusCode();

        var updatedJson = await updateResponse.Content.ReadAsStringAsync();
        Assert.Contains("\"status\":\"Completed\"", updatedJson);

        var list = await _client.GetFromJsonAsync<InterviewTopicDto[]>("/api/topics", JsonOptions);
        Assert.Contains(list!, topic => topic.Id == created.Id);

        var deleteResponse = await _client.DeleteAsync($"/api/topics/{created.Id}");
        Assert.Equal(HttpStatusCode.NoContent, deleteResponse.StatusCode);

        var getResponse = await _client.GetAsync($"/api/topics/{created.Id}");
        Assert.Equal(HttpStatusCode.NotFound, getResponse.StatusCode);
    }

    private static JsonSerializerOptions CreateJsonOptions()
    {
        var options = new JsonSerializerOptions(JsonSerializerDefaults.Web);
        options.Converters.Add(new JsonStringEnumConverter());
        return options;
    }
}
