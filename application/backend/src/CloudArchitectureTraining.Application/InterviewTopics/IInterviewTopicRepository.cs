using CloudArchitectureTraining.Domain.InterviewTopics;
using CloudArchitectureTraining.Application.Security;

namespace CloudArchitectureTraining.Application.InterviewTopics;

public interface IInterviewTopicRepository
{
    Task<IReadOnlyList<InterviewTopic>> ListAsync(
        ApplicationPrincipal principal,
        CancellationToken cancellationToken);
    Task<InterviewTopic?> GetAsync(
        Guid id,
        ApplicationPrincipal principal,
        CancellationToken cancellationToken);
    Task AddAsync(InterviewTopic topic, CancellationToken cancellationToken);
    void Remove(InterviewTopic topic);
    Task SaveChangesAsync(CancellationToken cancellationToken);
}
