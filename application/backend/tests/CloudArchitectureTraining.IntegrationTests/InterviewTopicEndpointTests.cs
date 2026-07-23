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
    private readonly TrainingApiFactory _factory;

    public InterviewTopicEndpointTests(TrainingApiFactory factory) => _factory = factory;

    [Fact]
    public async Task BusinessEndpointsRequireAnAuthenticatedApplicationRole()
    {
        var anonymousResponse = await _factory.CreateClient().GetAsync("/api/topics");
        Assert.Equal(HttpStatusCode.Unauthorized, anonymousResponse.StatusCode);

        var noRoleClient = _factory.CreateAuthenticatedClient("user-without-role");
        var forbiddenResponse = await noRoleClient.GetAsync("/api/topics");
        Assert.Equal(HttpStatusCode.Forbidden, forbiddenResponse.StatusCode);
    }

    [Fact]
    public async Task CrudRoundTripUsesStringStatusValues()
    {
        var client = _factory.CreateAuthenticatedClient("crud-user", "User");
        var createResponse = await client.PostAsJsonAsync(
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

        var updateResponse = await client.PutAsJsonAsync(
            $"/api/topics/{created.Id}",
            new SaveInterviewTopicRequest(
                created.Title,
                created.Cloud,
                created.Notes,
                TopicStatus.Completed));
        updateResponse.EnsureSuccessStatusCode();

        var updatedJson = await updateResponse.Content.ReadAsStringAsync();
        Assert.Contains("\"status\":\"Completed\"", updatedJson);

        var list = await client.GetFromJsonAsync<InterviewTopicDto[]>("/api/topics", JsonOptions);
        Assert.Contains(list!, topic => topic.Id == created.Id);

        var deleteResponse = await client.DeleteAsync($"/api/topics/{created.Id}");
        Assert.Equal(HttpStatusCode.NoContent, deleteResponse.StatusCode);

        var getResponse = await client.GetAsync($"/api/topics/{created.Id}");
        Assert.Equal(HttpStatusCode.NotFound, getResponse.StatusCode);
    }

    [Fact]
    public async Task OwnersAreIsolatedAndAdministratorsCanManageAllRecords()
    {
        var ownerClient = _factory.CreateAuthenticatedClient("owner-a", "User");
        var otherUserClient = _factory.CreateAuthenticatedClient("owner-b", "User");
        var administratorClient =
            _factory.CreateAuthenticatedClient("administrator", "Administrator");

        var createResponse = await ownerClient.PostAsJsonAsync(
            "/api/topics",
            new SaveInterviewTopicRequest(
                $"Owner isolation {Guid.NewGuid():N}",
                "Portable",
                "Only the owner or an administrator may see this.",
                TopicStatus.Planned));
        createResponse.EnsureSuccessStatusCode();
        var created = await createResponse.Content.ReadFromJsonAsync<InterviewTopicDto>(JsonOptions);
        Assert.NotNull(created);

        var otherUserList =
            await otherUserClient.GetFromJsonAsync<InterviewTopicDto[]>("/api/topics", JsonOptions);
        Assert.DoesNotContain(otherUserList!, topic => topic.Id == created.Id);

        Assert.Equal(
            HttpStatusCode.NotFound,
            (await otherUserClient.GetAsync($"/api/topics/{created.Id}")).StatusCode);
        Assert.Equal(
            HttpStatusCode.NotFound,
            (await otherUserClient.DeleteAsync($"/api/topics/{created.Id}")).StatusCode);

        var administratorList =
            await administratorClient.GetFromJsonAsync<InterviewTopicDto[]>("/api/topics", JsonOptions);
        Assert.Contains(administratorList!, topic => topic.Id == created.Id);

        Assert.Equal(
            HttpStatusCode.NoContent,
            (await administratorClient.DeleteAsync($"/api/topics/{created.Id}")).StatusCode);
    }

    private static JsonSerializerOptions CreateJsonOptions()
    {
        var options = new JsonSerializerOptions(JsonSerializerDefaults.Web);
        options.Converters.Add(new JsonStringEnumConverter());
        return options;
    }
}
