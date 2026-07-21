# ADR-0004: Use cloud-native OIDC providers with a common application authorization model

- Status: Accepted
- Date: 2026-07-21

## Context

The Angular single-page application and ASP.NET Core API must run on Azure and AWS. Authentication must be included in the first working version, use no browser client secret, and support the common `User` and `Administrator` roles without coupling business logic to one cloud identity provider.

Using a single provider for both clouds would simplify configuration but weaken the exercise's demonstration of cloud-native identity. Implementing custom authentication would create unnecessary security risk.

## Decision

- Azure uses Microsoft Entra ID.
- AWS uses an Amazon Cognito user pool.
- The Angular public client uses OpenID Connect Authorization Code with PKCE and provider-hosted authentication endpoints.
- The browser sends an access token in the HTTPS `Authorization: Bearer` header when calling the API.
- Tokens are held in memory and are not persisted to local storage or session storage.
- The API uses ASP.NET Core authentication and policy-based authorization.
- Cloud-specific token validation configuration is isolated in the composition/configuration layer. Business and data-access code consumes a normalized application principal.
- Provider roles are normalized to the application roles `User` and `Administrator`:
  - Entra application roles map to the common role names.
  - Cognito groups or a controlled token customization mechanism map to the same role names.
- Every owned entity stores the immutable identity subject and provider identifier needed to enforce ownership. Display names and email addresses are not authorization keys.
- Azure validates tokens in the API against the configured Entra issuer and audience.
- AWS API Gateway uses a JWT authorizer for Cognito before invoking Lambda. The API also validates required identity and authorization claims and does not trust client-supplied identity fields.
- `state`, `nonce`, exact redirect URIs, exact sign-out URIs, restrictive CORS, and short token lifetimes are required.
- Cloud administration is separate from application authentication and requires MFA.

## Security rules

- Anonymous access is limited to static content, authentication bootstrap, and health endpoints that expose no sensitive details.
- The implicit OAuth grant and resource-owner password grant are prohibited.
- A SPA client secret is prohibited because browser applications cannot protect it.
- Issuer, audience, signature algorithm, expiry, not-before time, and role/ownership claims are validated.
- Cross-user and user-to-administrator authorization tests are release gates.
- Authentication failures return generic responses and do not log tokens.

## Consequences

- Users have separate identities in the two training clouds unless federation is introduced later.
- Authentication configuration and test users must be provisioned independently in Entra ID and Cognito.
- The application remains portable because business authorization depends on normalized roles and subjects rather than provider SDKs.
- Memory-only tokens improve resistance to token theft through persistent browser storage but can require reauthentication after a page reload.
- API Gateway JWT authorization lets the AWS Lambda function operate without internet egress solely to retrieve Cognito signing keys, supporting the no-NAT design.

## Alternatives considered

### Use Microsoft Entra ID for both clouds

Rejected for the training baseline because it would not demonstrate AWS-native customer identity, although it remains valid for an enterprise with Entra as its central identity provider.

### Use Amazon Cognito for both clouds

Rejected for the same reason and because it would make the Azure workload unnecessarily dependent on AWS.

### Build custom username and password authentication

Rejected because credential storage, recovery, MFA, token issuance, and attack protection should not be reimplemented for this exercise.

### Use a backend-for-frontend and secure cookies

Deferred. It can further reduce browser token exposure but adds another stateful security boundary and does not fit the smallest training profile.

## Validation

- Automated login and protected-route test on Azure and AWS.
- Invalid signature, issuer, audience, expired-token, missing-role, and cross-user tests.
- Browser inspection confirming no token is stored in persistent web storage.
- CORS and security-header tests.

## References

- [Microsoft identity platform authorization code flow with PKCE](https://learn.microsoft.com/en-us/entra/identity-platform/v2-oauth2-auth-code-flow)
- [Amazon Cognito authorization code grants with PKCE](https://docs.aws.amazon.com/cognito/latest/developerguide/using-pkce-in-authorization-code.html)
- [Amazon Cognito app client security guidance](https://docs.aws.amazon.com/cognito/latest/developerguide/user-pool-settings-client-apps.html)
