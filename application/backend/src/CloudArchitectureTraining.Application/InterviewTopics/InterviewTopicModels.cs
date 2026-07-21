using CloudArchitectureTraining.Domain.InterviewTopics;

namespace CloudArchitectureTraining.Application.InterviewTopics;

public sealed record InterviewTopicDto(
    Guid Id,
    string Title,
    string Cloud,
    string Notes,
    TopicStatus Status,
    DateTimeOffset CreatedAtUtc,
    DateTimeOffset? UpdatedAtUtc);

public sealed record SaveInterviewTopicRequest(
    string Title,
    string Cloud,
    string Notes,
    TopicStatus Status = TopicStatus.Planned);
