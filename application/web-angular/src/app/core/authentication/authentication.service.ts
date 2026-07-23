import { computed, Injectable, signal } from '@angular/core';
import {
  InMemoryWebStorage,
  User,
  UserManager,
  WebStorageStateStore,
} from 'oidc-client-ts';
import { browserAuthenticationConfig } from '../api.config';

@Injectable({ providedIn: 'root' })
export class AuthenticationService {
  private readonly currentUser = signal<User | null>(null);
  private readonly manager = this.createManager();

  readonly enabled = browserAuthenticationConfig.enabled;
  readonly ready = signal(false);
  readonly error = signal('');
  readonly isAuthenticated = computed(
    () => !this.enabled || this.currentUser()?.expired === false,
  );
  readonly displayName = computed(
    () =>
      this.currentUser()?.profile.name ??
      this.currentUser()?.profile.preferred_username ??
      'Authenticated user',
  );
  readonly roles = computed(() => this.readRoles(this.currentUser()));

  constructor() {
    this.manager?.events.addUserLoaded((user) => this.currentUser.set(user));
    this.manager?.events.addUserUnloaded(() => this.currentUser.set(null));
    this.manager?.events.addAccessTokenExpired(() => this.currentUser.set(null));
  }

  async initialize(): Promise<void> {
    if (!this.enabled || !this.manager) {
      this.ready.set(true);
      return;
    }

    try {
      if (window.location.pathname === '/authentication/callback') {
        const user = await this.manager.signinRedirectCallback();
        this.currentUser.set(user);
        window.history.replaceState({}, document.title, '/');
      } else {
        this.currentUser.set(await this.manager.getUser());
      }
    } catch {
      this.error.set('Sign-in could not be completed. Please try again.');
      this.currentUser.set(null);
    } finally {
      this.ready.set(true);
    }
  }

  async login(): Promise<void> {
    if (!this.manager) return;
    this.error.set('');
    try {
      await this.manager.signinRedirect();
    } catch {
      this.error.set('Sign-in could not be started.');
    }
  }

  async logout(): Promise<void> {
    if (!this.manager) return;
    this.error.set('');
    try {
      await this.manager.signoutRedirect();
    } catch {
      this.error.set('Sign-out could not be completed.');
    }
  }

  accessToken(): string | null {
    const user = this.currentUser();
    return user && !user.expired ? user.access_token : null;
  }

  private createManager(): UserManager | null {
    if (!browserAuthenticationConfig.enabled) return null;
    if (
      !browserAuthenticationConfig.authority ||
      !browserAuthenticationConfig.clientId
    ) {
      throw new Error(
        'Authentication authority and client ID are required when browser authentication is enabled.',
      );
    }

    return new UserManager({
      authority: browserAuthenticationConfig.authority,
      client_id: browserAuthenticationConfig.clientId,
      redirect_uri: `${window.location.origin}/authentication/callback`,
      post_logout_redirect_uri: window.location.origin,
      response_type: 'code',
      scope: browserAuthenticationConfig.scope,
      automaticSilentRenew: true,
      loadUserInfo: false,
      stateStore: new WebStorageStateStore({ store: window.sessionStorage }),
      userStore: new WebStorageStateStore({ store: new InMemoryWebStorage() }),
    });
  }

  private readRoles(user: User | null): string[] {
    if (!user) return [];
    const profile = user.profile as Record<string, unknown>;
    const providerRoles =
      browserAuthenticationConfig.provider === 'Cognito'
        ? profile['cognito:groups']
        : profile['roles'];

    if (Array.isArray(providerRoles)) {
      return providerRoles.filter(
        (role): role is string => typeof role === 'string',
      );
    }

    return typeof providerRoles === 'string' ? [providerRoles] : [];
  }
}
