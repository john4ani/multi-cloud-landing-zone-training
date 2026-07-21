import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { apiBaseUrl } from '../../core/api.config';
import { InterviewTopic, SaveInterviewTopicRequest } from './interview-topic';

@Injectable({ providedIn: 'root' })
export class InterviewTopicService {
  private readonly url = `${apiBaseUrl}/topics`;

  constructor(private readonly http: HttpClient) {}

  list(): Observable<InterviewTopic[]> {
    return this.http.get<InterviewTopic[]>(this.url);
  }

  create(request: SaveInterviewTopicRequest): Observable<InterviewTopic> {
    return this.http.post<InterviewTopic>(this.url, request);
  }

  remove(id: string): Observable<void> {
    return this.http.delete<void>(`${this.url}/${id}`);
  }
}
