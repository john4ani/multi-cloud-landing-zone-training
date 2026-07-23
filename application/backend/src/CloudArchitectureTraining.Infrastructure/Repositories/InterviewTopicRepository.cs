using CloudArchitectureTraining.Application.InterviewTopics;
using CloudArchitectureTraining.Application.Security;
using CloudArchitectureTraining.Domain.InterviewTopics;
using CloudArchitectureTraining.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace CloudArchitectureTraining.Infrastructure.Repositories;

public sealed class InterviewTopicRepository(TrainingDbContext dbContext) : IInterviewTopicRepository
{
    public async Task<IReadOnlyList<InterviewTopic>> ListAsync(
        ApplicationPrincipal principal,
        CancellationToken cancellationToken)
    {
        var query = dbContext.InterviewTopics.AsQueryable();
        if (!principal.IsAdministrator)
        {
            query = query.Where(x =>
                x.OwnerProvider == principal.Provider &&
                x.OwnerSubject == principal.Subject);
        }

        return await query.OrderBy(x => x.Title).ToListAsync(cancellationToken);
    }

    public Task<InterviewTopic?> GetAsync(
        Guid id,
        ApplicationPrincipal principal,
        CancellationToken cancellationToken) =>
        dbContext.InterviewTopics.SingleOrDefaultAsync(
            x => x.Id == id &&
                (principal.IsAdministrator ||
                    (x.OwnerProvider == principal.Provider &&
                     x.OwnerSubject == principal.Subject)),
            cancellationToken);

    public Task AddAsync(InterviewTopic topic, CancellationToken cancellationToken) =>
        dbContext.InterviewTopics.AddAsync(topic, cancellationToken).AsTask();

    public void Remove(InterviewTopic topic) => dbContext.InterviewTopics.Remove(topic);

    public Task SaveChangesAsync(CancellationToken cancellationToken) =>
        dbContext.SaveChangesAsync(cancellationToken);
}
