using CloudArchitectureTraining.Domain.InterviewTopics;
using Microsoft.EntityFrameworkCore;

namespace CloudArchitectureTraining.Infrastructure.Persistence;

public sealed class TrainingDbContext(DbContextOptions<TrainingDbContext> options) : DbContext(options)
{
    public DbSet<InterviewTopic> InterviewTopics => Set<InterviewTopic>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        var topic = modelBuilder.Entity<InterviewTopic>();
        topic.ToTable("interview_topics");
        topic.HasKey(x => x.Id);
        topic.Property(x => x.Title).HasMaxLength(200).IsRequired();
        topic.Property(x => x.Cloud).HasMaxLength(40).IsRequired();
        topic.Property(x => x.Notes).HasMaxLength(4000);
        topic.Property(x => x.Status).HasConversion<string>().HasMaxLength(20);
    }
}
