export type AuthenticationProvider = 'Entra' | 'Cognito';

export interface BrowserAuthenticationConfig {
  enabled: boolean;
  provider: AuthenticationProvider;
  authority: string;
  clientId: string;
  scope: string;
}

declare global {
  interface Window {
    cloudTrainingConfig?: {
      apiBaseUrl?: string;
      authentication?: Partial<BrowserAuthenticationConfig>;
    };
  }
}

export const apiBaseUrl =
  window.cloudTrainingConfig?.apiBaseUrl ?? 'http://localhost:5080/api';

const configuredAuthentication = window.cloudTrainingConfig?.authentication;
export const browserAuthenticationConfig: BrowserAuthenticationConfig = {
  enabled: configuredAuthentication?.enabled === true,
  provider: configuredAuthentication?.provider ?? 'Entra',
  authority: configuredAuthentication?.authority ?? '',
  clientId: configuredAuthentication?.clientId ?? '',
  scope: configuredAuthentication?.scope ?? 'openid profile email',
};
