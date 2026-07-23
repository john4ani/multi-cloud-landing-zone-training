# Security data-flow diagram

- Status: Implemented locally; Azure and AWS sign-in evidence pending
- Scope: Local, Azure training, and AWS training workload variants

This logical diagram is intentionally provider-neutral. The [Azure deployment](azure-deployment.md) and [AWS deployment](aws-deployment.md) diagrams provide the cloud-specific topology.

```mermaid
flowchart LR
    user["Authenticated user"]
    engineer["Administrator / engineer\nMFA enabled"]

    subgraph tb1["TB1 — User device and public internet"]
        browser["Angular application\nTokens held in memory"]
    end

    subgraph tb2["TB2 — External identity provider"]
        idp["Microsoft Entra ID or\nAmazon Cognito"]
    end

    subgraph tb3["TB3 — Public cloud ingress"]
        edge["Azure Static Web Apps or\nCloudFront + S3"]
        ingress["Container Apps ingress or\nAPI Gateway"]
    end

    subgraph tb4["TB4 — Application execution"]
        api["ASP.NET Core API\nAuthentication, authorization, validation"]
        telemetry["Sanitized logs, metrics,\nhealth and audit events"]
    end

    subgraph tb5["TB5 — Data boundary"]
        db[("Azure SQL or\nRDS PostgreSQL")]
    end

    subgraph tb6["TB6 — Delivery and cloud administration"]
        repo["Private source repository"]
        pipeline["CI/CD pipeline\nPlan, policy, approval, apply"]
        state[("Encrypted Terraform state")]
        cloud["Azure or AWS control plane"]
    end

    user -->|"1. HTTPS"| browser
    browser -->|"2. Authorization Code + PKCE"| idp
    idp -->|"3. ID and access tokens"| browser
    browser -->|"4. Static content"| edge
    browser -->|"5. HTTPS API + bearer token"| ingress
    ingress -->|"6. Authenticated request"| api
    api -->|"7. Validate issuer, audience, expiry and roles"| idp
    api -->|"8. Parameterized query over TLS"| db
    db -->|"9. Authorized records"| api
    api -->|"10. Sanitized response"| browser
    api -->|"11. Redacted telemetry"| telemetry

    engineer -->|"12. Reviewed change"| repo
    repo -->|"13. Protected pipeline trigger"| pipeline
    pipeline -->|"14. OIDC short-lived identity"| cloud
    pipeline <-->|"15. Encrypted state with locking"| state
    cloud -->|"16. Deploy configuration"| edge
    cloud -->|"17. Deploy configuration"| ingress
    cloud -->|"18. Deploy configuration"| api
    cloud -->|"19. Deploy configuration"| db
```

## Trust boundaries

| Boundary | Main concern | Required control |
|---|---|---|
| TB1 | Untrusted browser, malicious input, stolen token | PKCE, CSP, validation, no local-storage tokens, HTTPS |
| TB2 | Incorrect identity-provider or token configuration | Exact issuer/audience validation, state, nonce, short token lifetime |
| TB3 | Internet exposure and cost-exhaustion traffic | HTTPS, restrictive CORS, throttling, quotas, security headers |
| TB4 | Authorization bypass, injection, secret leakage | Policy-based authorization, ownership checks, parameterized access, redaction |
| TB5 | Database exposure, data loss, excessive privilege | Private/restricted networking, TLS, least privilege, encryption, reseed/restore procedure |
| TB6 | Supply-chain compromise and excessive deployment privilege | Protected review, signed/verified dependencies where practical, OIDC, separate plan/apply roles, policy gates |

## Assets

- Identity tokens, role claims, and authentication configuration.
- Synthetic interview data and ownership identifiers.
- Database credentials where token-based access is unavailable.
- Terraform state, which can contain sensitive infrastructure metadata.
- Source code, build dependencies, container images, and deployment artifacts.
- Pipeline identities and cloud role assignments.
- Security policies, approvals, logs, and audit evidence.
