declare global {
  interface Window {
    cloudTrainingConfig?: {
      apiBaseUrl?: string;
    };
  }
}

export const apiBaseUrl =
  window.cloudTrainingConfig?.apiBaseUrl ?? 'http://localhost:5080/api';
