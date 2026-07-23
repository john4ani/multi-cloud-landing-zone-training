# Authentication and authorization

The authentication slice is implemented without deploying cloud resources. Local development remains friction-free because `Authentication:Enabled` and browser authentication both default to `false`. Real Microsoft Entra ID or Amazon Cognito sign-in requires an explicit test deployment and provider configuration.

## Implemented behavior

- Angular uses OpenID Connect Authorization Code with PKCE through `oidc-client-ts`.
- Tokens and the authenticated user are stored in memory. Session storage holds only transient OIDC request state required to validate the callback.
- The bearer interceptor sends the access token only to the configured API base URL.
- The API permits anonymous access only to health checks when authentication is enabled.
- Business endpoints require `User` or `Administrator`.
- A user can query and change only records owned by their immutable provider/subject identity.
- An administrator can query and change all records.
- Azure reads Entra `roles`; AWS reads Cognito `cognito:groups`.

## Runtime browser configuration

The deployment workflow creates `config.js` beside the Angular application:

```javascript
globalThis.cloudTrainingConfig = {
  apiBaseUrl: "/api",
  authentication: {
    enabled: true,
    provider: "Entra",
    authority: "https://login.microsoftonline.com/<tenant-id>/v2.0",
    clientId: "<spa-client-id>",
    scope: "openid profile email api://<api-client-id>/access_as_user"
  }
};
```

Use `provider: "Cognito"`, the Terraform-provided Cognito issuer, client ID, and `openid profile email` in AWS. Do not put a client secret, access token, or refresh token in `config.js`.

## Microsoft Entra ID setup

Create two app registrations in the tenant:

1. API registration:
   - Set the Application ID URI to `api://<api-client-id>`.
   - Expose delegated scope `access_as_user`.
   - Define `User` and `Administrator` app roles with `User/Groups` as allowed member types.
2. SPA registration:
   - Add SPA redirect URIs `http://localhost:4200/authentication/callback` and `https://<deployed-host>/authentication/callback`.
   - Add logout URIs `http://localhost:4200` and `https://<deployed-host>`.
   - Add delegated permission `api://<api-client-id>/access_as_user` and grant the required consent.
   - Do not create a client secret.
3. In Enterprise applications, assign each test user or group to the API's `User` or `Administrator` role.

Configure these GitHub repository variables:

| Variable | Value |
|---|---|
| `AZURE_AUTHENTICATION_ENABLED` | `true` only for the approved authentication test |
| `AZURE_ENTRA_AUTHORITY` | `https://login.microsoftonline.com/<tenant-id>/v2.0` |
| `AZURE_ENTRA_API_CLIENT_ID` | API registration application/client ID |
| `AZURE_ENTRA_SPA_CLIENT_ID` | SPA registration application/client ID |
| `AZURE_ENTRA_API_SCOPE` | `api://<api-client-id>/access_as_user` |

The Terraform deployment guard rejects an enabled configuration with any missing value.

## Amazon Cognito setup

Terraform creates the user pool, public SPA client, hosted domain, exact deployed and local callback/logout URLs, and the `User` and `Administrator` groups. It enables only the authorization-code flow and creates no client secret.

After deployment, create synthetic test users and assign each one to exactly the intended group:

```powershell
aws cognito-idp admin-create-user `
  --user-pool-id <user-pool-id> `
  --username <test-email>

aws cognito-idp admin-add-user-to-group `
  --user-pool-id <user-pool-id> `
  --username <test-email> `
  --group-name User
```

Repeat with `--group-name Administrator` for the administrator test account. Set repository variable `AWS_AUTHENTICATION_ENABLED` to `true` only for the approved authentication test deployment.

## Authenticated smoke tests

The normal smoke test remains unauthenticated while authentication is disabled. For an enabled environment, create a short-lived access token through the provider and store it only as the appropriate protected environment secret:

- `AZURE_AUTHENTICATION_TEST_ACCESS_TOKEN`
- `AWS_AUTHENTICATION_TEST_ACCESS_TOKEN`

The deploy workflow passes it to `scripts/smoke-test.ps1`; the script applies it only to business API calls. The health check and frontend request remain anonymous. Delete or rotate the secret after the exercise.

## Required validation evidence

For each cloud, capture:

1. Unauthenticated business request returns `401`.
2. Authenticated user can create/read/update/delete their own record.
3. A second user cannot discover or modify that record and receives `404`.
4. Administrator can access the records.
5. Sign-out completes and no token remains in local storage or session storage.
6. CORS accepts only the deployed frontend origin.

Destroy the AWS workload promptly after testing. Authentication services may qualify for free allowances, but this repository does not claim that an entire deployment is guaranteed to have zero cost.
