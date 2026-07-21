export type TopicStatus = 'Planned' | 'InProgress' | 'Completed';

export interface InterviewTopic {
  id: string;
  title: string;
  cloud: string;
  notes: string;
  status: TopicStatus;
  createdAtUtc: string;
  updatedAtUtc?: string;
}

export interface SaveInterviewTopicRequest {
  title: string;
  cloud: string;
  notes: string;
  status: TopicStatus;
}
