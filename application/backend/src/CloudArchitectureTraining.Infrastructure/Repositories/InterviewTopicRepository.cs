using CloudArchitectureTraining.Application.InterviewTopics;
using CloudArchitectureTraining.Domain.InterviewTopics;
using CloudArchitectureTraining.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace CloudArchitectureTraining.Infrastructure.Repositories;

public sealed class InterviewTopicRepository(TrainingDbContext dbContext) : IInterviewTopicRepository
{
    public async Task<IReadOnlyList<InterviewTopic>> ListAsync(CancellationToken cancellationToken) =>
        await dbContext.InterviewTopics.OrderBy(x => x.Title).ToListAsync(cancellationToken);

    public Task<InterviewTopic?> GetAsync(Guid id, CancellationToken cancellationToken) =>
        dbContext.InterviewTopics.SingleOrDefaultAsync(x => x.Id == id, cancellationToken);

    public Task AddAsync(InterviewTopic topic, CancellationToken cancellationToken) =>
        dbContext.InterviewTopics.AddAsync(topic, cancellationToken).AsTask();

    public void Remove(InterviewTopic topic) => dbContext.InterviewTopics.Remove(topic);

    public Task SaveChangesAsync(CancellationToken cancellationToken) =>
        dbContext.SaveChangesAsync(cancellationToken);
}
