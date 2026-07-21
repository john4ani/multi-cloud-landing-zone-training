# ADR-0001: Use Documentation as Code and diagram-first design

- Status: Accepted
- Date: 2026-07-21

## Context

The project is intended to demonstrate cloud architecture skills and must be understandable to engineers who did not participate in its implementation. Application, infrastructure, security policy, operational behavior, and cost controls will evolve together.

## Decision

Store documentation with the solution in version control. Use Markdown for narrative content, Mermaid for diagrams, ADRs for significant decisions, OpenAPI for the HTTP contract, and generated Terraform module references.

Architecture diagrams and relevant decisions are created or updated before implementation. Documentation validation is included in continuous integration, and related documentation changes are part of the same review as code changes.

## Consequences

- Architecture changes are visible and reviewable as text diffs.
- Documentation versions remain aligned with solution versions.
- Contributors must treat documentation work as part of completion.
- Automated checks and generation tooling must be maintained.
- Mermaid may not express every advanced visual; exceptions require retaining an editable source format.

## Alternatives considered

### External wiki only

Rejected because its version and review lifecycle can drift from the implementation.

### Binary diagrams only

Rejected because binary changes are difficult to review and automate.

### Documentation after implementation

Rejected because architectural intent and trade-offs are most useful before irreversible implementation decisions are made.
