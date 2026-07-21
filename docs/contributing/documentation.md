# Documentation contribution rules

## Documentation as Code

Documentation follows the same workflow as application and infrastructure code: source control, review, automated validation, version history, and ownership.

## Diagram-first workflow

1. Update the relevant Mermaid diagram to show the proposed architecture.
2. Record a significant decision or trade-off in an ADR.
3. Review security, cost, reliability, operational, and performance effects.
4. Implement the change.
5. Generate API and Terraform reference documentation.
6. Verify links, diagrams, examples, and runbooks in continuous integration.

## Required documentation by change type

| Change | Required documentation |
|---|---|
| New service or major component | Architecture diagram, ADR, cost impact, security impact |
| Terraform module | README, inputs, outputs, example, policies, destruction behavior |
| API endpoint | OpenAPI description, examples, authentication and error behavior |
| Operational behavior | Runbook, health signal, alert or diagnostic guidance |
| Security control | Threat or risk addressed, enforcement point, test, exception process |
| Policy | Purpose, scope, severity, compliant and denied examples |

## Source formats

- Markdown is the default narrative format.
- Mermaid is the default diagram format.
- ADRs capture decisions and alternatives.
- OpenAPI is the source of truth for the HTTP API contract.
- Terraform definitions are the source for generated module reference tables.

Binary-only diagrams and manually maintained copies of generated reference content are avoided because they are difficult to review and frequently drift.

## Pull request checklist

- [ ] Architecture and requirements remain accurate.
- [ ] Relevant diagrams are updated.
- [ ] An ADR was added or updated when a significant decision changed.
- [ ] Security and cost implications are documented.
- [ ] Commands and examples were verified.
- [ ] Generated documentation was refreshed.
- [ ] Links and Mermaid syntax pass validation.
