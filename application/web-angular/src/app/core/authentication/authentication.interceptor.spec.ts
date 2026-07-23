import {
  HttpClient,
  provideHttpClient,
  withInterceptors,
} from '@angular/common/http';
import {
  HttpTestingController,
  provideHttpClientTesting,
} from '@angular/common/http/testing';
import { TestBed } from '@angular/core/testing';
import { apiBaseUrl } from '../api.config';
import { authenticationInterceptor } from './authentication.interceptor';
import { AuthenticationService } from './authentication.service';

describe('authenticationInterceptor', () => {
  let httpTesting: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [
        provideHttpClient(withInterceptors([authenticationInterceptor])),
        provideHttpClientTesting(),
        {
          provide: AuthenticationService,
          useValue: { accessToken: () => 'test-access-token' },
        },
      ],
    });
    httpTesting = TestBed.inject(HttpTestingController);
  });

  afterEach(() => httpTesting.verify());

  it('adds a bearer token only to the configured API', () => {
    const http = TestBed.inject(HttpClient);

    http.get(`${apiBaseUrl}/topics`).subscribe();
    const apiRequest = httpTesting.expectOne(`${apiBaseUrl}/topics`);
    expect(apiRequest.request.headers.get('Authorization')).toBe(
      'Bearer test-access-token',
    );
    apiRequest.flush([]);

    http.get('https://example.test/public').subscribe();
    const externalRequest = httpTesting.expectOne('https://example.test/public');
    expect(externalRequest.request.headers.has('Authorization')).toBe(false);
    externalRequest.flush({});
  });
});
