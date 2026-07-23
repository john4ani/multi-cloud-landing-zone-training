namespace CloudArchitectureTraining.Domain.InterviewTopics;

public sealed class InterviewTopic
{
    private InterviewTopic() { }

    public InterviewTopic(
        string ownerProvider,
        string ownerSubject,
        string title,
        string cloud,
        string notes = "",
        TopicStatus status = TopicStatus.Planned)
    {
        Id = Guid.NewGuid();
        SetOwner(ownerProvider, ownerSubject);
        Update(title, cloud, notes, status);
        CreatedAtUtc = DateTimeOffset.UtcNow;
        UpdatedAtUtc = null;
    }

    public Guid Id { get; private set; }
    public string OwnerProvider { get; private set; } = string.Empty;
    public string OwnerSubject { get; private set; } = string.Empty;
    public string Title { get; private set; } = string.Empty;
    public string Cloud { get; private set; } = string.Empty;
    public string Notes { get; private set; } = string.Empty;
    public TopicStatus Status { get; private set; }
    public DateTimeOffset CreatedAtUtc { get; private set; }
    public DateTimeOffset? UpdatedAtUtc { get; private set; }

    private void SetOwner(string ownerProvider, string ownerSubject)
    {
        if (string.IsNullOrWhiteSpace(ownerProvider))
        {
            throw new ArgumentException("An owner provider is required.", nameof(ownerProvider));
        }

        if (string.IsNullOrWhiteSpace(ownerSubject))
        {
            throw new ArgumentException("An owner subject is required.", nameof(ownerSubject));
        }

        OwnerProvider = ownerProvider.Trim();
        OwnerSubject = ownerSubject.Trim();
    }

    public void Update(string title, string cloud, string notes, TopicStatus status)
    {
        if (string.IsNullOrWhiteSpace(title))
        {
            throw new ArgumentException("A title is required.", nameof(title));
        }

        if (string.IsNullOrWhiteSpace(cloud))
        {
            throw new ArgumentException("A cloud is required.", nameof(cloud));
        }

        Title = title.Trim();
        Cloud = cloud.Trim();
        Notes = notes?.Trim() ?? string.Empty;
        Status = status;
        UpdatedAtUtc = DateTimeOffset.UtcNow;
    }
}
