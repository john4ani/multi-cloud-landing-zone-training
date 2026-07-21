using CloudArchitectureTraining.Domain.InterviewTopics;

namespace CloudArchitectureTraining.Application.InterviewTopics;

public sealed class InterviewTopicService(IInterviewTopicRepository repository)
{
    public async Task<IReadOnlyList<InterviewTopicDto>> ListAsync(CancellationToken cancellationToken) =>
        (await repository.ListAsync(cancellationToken)).Select(Map).ToArray();

    public async Task<InterviewTopicDto?> GetAsync(Guid id, CancellationToken cancellationToken)
    {
        var topic = await repository.GetAsync(id, cancellationToken);
        return topic is null ? null : Map(topic);
    }

    public async Task<InterviewTopicDto> CreateAsync(
        SaveInterviewTopicRequest request,
        CancellationToken cancellationToken)
    {
        var topic = new InterviewTopic(request.Title, request.Cloud, request.Notes, request.Status);
        await repository.AddAsync(topic, cancellationToken);
        await repository.SaveChangesAsync(cancellationToken);
        return Map(topic);
    }

    public async Task<InterviewTopicDto?> UpdateAsync(
        Guid id,
        SaveInterviewTopicRequest request,
        CancellationToken cancellationToken)
    {
        var topic = await repository.GetAsync(id, cancellationToken);
        if (topic is null) return null;

        topic.Update(request.Title, request.Cloud, request.Notes, request.Status);
        await repository.SaveChangesAsync(cancellationToken);
        return Map(topic);
    }

    public async Task<bool> DeleteAsync(Guid id, CancellationToken cancellationToken)
    {
        var topic = await repository.GetAsync(id, cancellationToken);
        if (topic is null) return false;

        repository.Remove(topic);
        await repository.SaveChangesAsync(cancellationToken);
        return true;
    }

    private static InterviewTopicDto Map(InterviewTopic topic) => new(
        topic.Id,
        topic.Title,
        topic.Cloud,
        topic.Notes,
        topic.Status,
        topic.CreatedAtUtc,
        topic.UpdatedAtUtc);
}
