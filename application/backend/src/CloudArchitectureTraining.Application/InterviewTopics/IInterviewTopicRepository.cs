using CloudArchitectureTraining.Domain.InterviewTopics;

namespace CloudArchitectureTraining.Application.InterviewTopics;

public interface IInterviewTopicRepository
{
    Task<IReadOnlyList<InterviewTopic>> ListAsync(CancellationToken cancellationToken);
    Task<InterviewTopic?> GetAsync(Guid id, CancellationToken cancellationToken);
    Task AddAsync(InterviewTopic topic, CancellationToken cancellationToken);
    void Remove(InterviewTopic topic);
    Task SaveChangesAsync(CancellationToken cancellationToken);
}
