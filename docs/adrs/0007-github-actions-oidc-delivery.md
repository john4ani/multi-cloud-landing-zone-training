# ADR-0007: Use GitHub Actions with OIDC and gated deployment workflows

- Status: Accepted
- Date: 2026-07-21

## Context

The project needs a single, understandable delivery workflow for Angular, .NET, Terraform, Policy as Code, documentation, Azure, and AWS. The workflow must avoid stored cloud credentials, separate read/plan access from deployment access, retain review evidence, and remain suitable for a private training repository.

## Decision

- Use a private GitHub repository and GitHub Actions.
- Authenticate to Azure and AWS using GitHub's OIDC identity tokens and narrowly scoped cloud federation:
  - Azure federated credentials trust only the intended repository, branch or protected environment, and audience.
  - AWS IAM role trust restricts repository, branch/environment subject, and the `sts.amazonaws.com` audience.
- Long-lived Azure client secrets and AWS access keys are prohibited.
- Use separate cloud roles/identities for:
  - Pull-request validation and read-only Terraform plan.
  - Approved Terraform apply and application deployment.
  - Runtime workload execution.
- Grant `id-token: write` only to jobs that authenticate to a cloud. Default workflow token permissions are read-only.
- Pin third-party GitHub Actions to reviewed full commit SHAs. Dependabot or an equivalent reviewed process proposes updates.
- Use GitHub protected environments for Azure and AWS apply jobs, with manual approval and environment-scoped non-secret configuration.
- Serialize apply jobs per cloud, environment, and Terraform state key.
- Do not run privileged cloud plans for untrusted fork pull requests.

## Workflow stages

1. Documentation and source formatting.
2. Markdown links and Mermaid validation.
3. Angular and .NET restore, build, unit tests, and dependency scan.
4. Secret, source, container, and Terraform static scanning.
5. Terraform formatting, initialization, validation, and linting.
6. OIDC authentication using the plan identity.
7. Terraform plan converted to JSON and evaluated by OPA/Rego.
8. Plan summary and security/cost results attached to the review; sensitive binary plan retained only for the approval window.
9. Protected-environment approval.
10. OIDC authentication using the apply identity and application of the exact reviewed plan.
11. Application deployment, database migration, smoke tests, and evidence capture.
12. On-demand or scheduled AWS destruction workflow with post-destroy inventory verification.

## Security controls

- Cloud trust policies bind identity to the exact repository and protected deployment context.
- Plan and apply permissions are different; neither runtime identity can modify infrastructure.
- Environments prevent an unreviewed pull request from reaching apply credentials.
- Workflow and policy files are covered by required review ownership.
- Logs and artifacts exclude tokens, credentials, connection strings, state, and sensitive plan content.
- Artifact retention is explicit and short.
- Production-style apply always consumes the reviewed saved plan rather than creating a new unreviewed plan.

## Consequences

- One delivery system can demonstrate multi-cloud workload deployment and common policy gates.
- GitHub becomes a control-plane dependency for deployment, although local validation and emergency documented recovery remain possible.
- OIDC bootstrap still requires an initial privileged configuration in each cloud.
- GitHub-hosted runner usage must remain within the repository/account allowance.
- Protected environment availability and behavior depend on the selected GitHub plan and repository visibility; this must be verified before implementation.

## Alternatives considered

### Azure DevOps

Not selected because GitHub Actions provides a simpler neutral demonstration across Azure and AWS for this repository. Reconsider if an employer-specific exercise requires Azure DevOps.

### Separate Azure and AWS CI systems

Rejected because it would duplicate policy, testing, documentation, and approval workflows.

### Local manual deployment

Rejected as the normal path because it weakens repeatability, review evidence, identity control, and operational-excellence learning.

### Store service-principal secrets in GitHub

Rejected because GitHub OIDC supports short-lived federation to both clouds.

## Validation

- OIDC trust tests reject a different repository, branch, environment, and audience.
- Plan identity cannot apply; apply identity is unavailable before approval.
- Runtime identities cannot read Terraform state or modify infrastructure.
- A deliberately failing OPA policy blocks deployment.
- The apply job consumes the reviewed plan checksum.
- AWS destruction completes and a post-destroy inventory shows only explicitly retained bootstrap resources.

## References

- [GitHub Actions OIDC for AWS](https://docs.github.com/en/actions/how-tos/secure-your-work/security-harden-deployments/oidc-in-aws)
- [GitHub Actions OIDC reference](https://docs.github.com/en/actions/reference/security/oidc)
- [Authenticate GitHub Actions to Azure](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure)
