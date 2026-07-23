import { HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { apiBaseUrl } from '../api.config';
import { AuthenticationService } from './authentication.service';

export const authenticationInterceptor: HttpInterceptorFn = (request, next) => {
  const token = inject(AuthenticationService).accessToken();
  if (!token || !request.url.startsWith(apiBaseUrl)) {
    return next(request);
  }

  return next(
    request.clone({
      setHeaders: { Authorization: `Bearer ${token}` },
    }),
  );
};
