# Security risk register

- Status: Accepted baseline
- Scoring: Likelihood (L) 1–5 × Impact (I) 1–5
- Severity: Low 1–4, Moderate 5–9, High 10–16, Critical 17–25

Residual scores assume all listed controls are implemented and verified.

| ID | Risk | STRIDE | Inherent L×I | Controls and required evidence | Residual L×I | Disposition |
|---|---|---|---:|---|---:|---|
| R-001 | Stolen or forged browser access token permits account access. | S, E, I | 4×4=16 High | PKCE, issuer/audience/algorithm validation, short lifetime, memory-only token, CSP, authentication tests | 2×4=8 Moderate | Mitigate |
| R-002 | Broken object-level authorization exposes or modifies another user's records. | E, I, T | 4×4=16 High | Owner predicate in data access, administrator policy, cross-user integration tests | 1×4=4 Low | Mitigate |
| R-003 | Injection or malformed input affects the database or API. | T, D, I | 3×4=12 High | Typed request models, validation, EF Core parameterization, bounded inputs, error handling, security tests | 1×4=4 Low | Mitigate |
| R-004 | Browser XSS steals a token or performs authenticated operations. | S, T, I | 3×4=12 High | Angular encoding, no unsafe HTML, CSP, dependency scanning, memory-only tokens, browser tests | 2×4=8 Moderate | Mitigate |
| R-005 | Database is reached from an unauthorized network source. | S, I, T | 3×5=15 High | AWS private RDS and security groups; Azure narrow firewall exception; TLS; least-privilege identity; network tests | 2×4=8 Moderate | Mitigate and accept training exception |
| R-006 | Secret or Terraform state leaks through Git, logs, plans, outputs, or artifacts. | I | 4×5=20 Critical | OIDC, encrypted restricted state, sensitive outputs, scanning, redaction tests, `.gitignore`, artifact retention policy | 1×5=5 Moderate | Mitigate |
| R-007 | Compromised dependency, container base, or CI action alters the workload. | T, E | 3×5=15 High | Lock files, pinned versions, trusted registries, vulnerability and license scan, SBOM, reviewed updates | 2×4=8 Moderate | Mitigate |
| R-008 | Excessive Terraform or runtime permissions cause account compromise. | E, T, I | 3×5=15 High | Separate plan/apply/runtime identities, least privilege, OPA policies, permission boundaries, cloud audit evidence | 1×5=5 Moderate | Mitigate |
| R-009 | Request flood or inefficient query exhausts capacity or Free Tier credits. | D | 4×3=12 High | Throttling, quotas, pagination, timeouts, concurrency caps, budgets, alerts, usage tests | 2×3=6 Moderate | Mitigate and monitor |
| R-010 | Logs disclose tokens, credentials, or user-entered notes. | I | 3×4=12 High | Structured allow-listed logging, request-body exclusion, redaction tests, short retention | 1×4=4 Low | Mitigate |
| R-011 | Unreviewed infrastructure or policy change bypasses guardrails. | T, E, R | 3×4=12 High | Protected branches, required checks, immutable reviewed plan, approval gate, drift checks | 1×4=4 Low | Mitigate |
| R-012 | Destruction or database failure loses training progress. | T, D | 3×2=6 Moderate | Synthetic data, migrations, reproducible seed, optional backup, restore/reseed runbook | 2×2=4 Low | Accept |
| R-013 | Azure SQL's public service endpoint increases attack surface. | S, I, D | 3×4=12 High | Synthetic data, narrow firewall, Entra authentication, TLS, auditing, no direct browser path, expiring exception | 2×4=8 Moderate | Accept for training only |
| R-014 | Budget alerts fail to prevent unexpected charges. | D | 3×3=9 Moderate | Expensive-resource deny list, smallest capacities, expiry metadata, AWS teardown, billing review | 2×3=6 Moderate | Mitigate and accept |
| R-015 | Administrator account compromise bypasses application controls. | S, E, T | 3×5=15 High | MFA, no root use, short-lived sessions, separate roles, audit logs, least privilege | 1×5=5 Moderate | Mitigate |

## Ownership and review

The project owner accepts residual training risks. A risk becomes blocking when it reaches Critical after controls, involves non-synthetic data, or invalidates an accepted non-functional requirement. Review risks with every architecture ADR and before each cloud deployment.
