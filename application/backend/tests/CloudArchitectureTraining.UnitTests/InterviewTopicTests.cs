using CloudArchitectureTraining.Domain.InterviewTopics;

namespace CloudArchitectureTraining.UnitTests;

public sealed class InterviewTopicTests
{
    [Fact]
    public void ConstructorTrimsRequiredValues()
    {
        var topic = new InterviewTopic("Local", "user-1", "  Identity  ", " Azure ");

        Assert.Equal("Identity", topic.Title);
        Assert.Equal("Azure", topic.Cloud);
        Assert.Equal(TopicStatus.Planned, topic.Status);
    }

    [Fact]
    public void ConstructorRejectsAnEmptyTitle() =>
        Assert.Throws<ArgumentException>(() =>
            new InterviewTopic("Local", "user-1", " ", "AWS"));

    [Fact]
    public void ConstructorRejectsAnEmptyOwner() =>
        Assert.Throws<ArgumentException>(() =>
            new InterviewTopic("Local", " ", "Identity", "AWS"));
}
