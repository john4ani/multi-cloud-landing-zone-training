import { Component, OnInit, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { InterviewTopic } from './features/topics/interview-topic';
import { InterviewTopicService } from './features/topics/interview-topic.service';

@Component({
  selector: 'app-root',
  imports: [ReactiveFormsModule],
  templateUrl: './app.html',
  styleUrl: './app.scss',
})
export class App implements OnInit {
  protected readonly topics = signal<InterviewTopic[]>([]);
  protected readonly loading = signal(true);
  protected readonly error = signal('');

  protected readonly form;

  constructor(
    formBuilder: FormBuilder,
    private readonly topicService: InterviewTopicService,
  ) {
    this.form = formBuilder.nonNullable.group({
      title: ['', [Validators.required, Validators.maxLength(200)]],
      cloud: ['Azure', Validators.required],
      notes: ['', Validators.maxLength(4000)],
      status: ['Planned' as const, Validators.required],
    });
  }

  ngOnInit(): void {
    this.refresh();
  }

  protected refresh(): void {
    this.loading.set(true);
    this.topicService.list().subscribe({
      next: (topics) => {
        this.topics.set(topics);
        this.loading.set(false);
      },
      error: () => {
        this.error.set('The API is unavailable. Start the backend and local database, then try again.');
        this.loading.set(false);
      },
    });
  }

  protected addTopic(): void {
    if (this.form.invalid) return;

    this.error.set('');
    this.topicService.create(this.form.getRawValue()).subscribe({
      next: (topic) => {
        this.topics.update((topics) => [...topics, topic].sort((a, b) => a.title.localeCompare(b.title)));
        this.form.reset({ title: '', cloud: 'Azure', notes: '', status: 'Planned' });
      },
      error: () => this.error.set('The topic could not be saved.'),
    });
  }

  protected removeTopic(id: string): void {
    this.topicService.remove(id).subscribe({
      next: () => this.topics.update((topics) => topics.filter((topic) => topic.id !== id)),
      error: () => this.error.set('The topic could not be removed.'),
    });
  }
}
