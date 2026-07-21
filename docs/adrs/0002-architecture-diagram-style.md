# ADR-0002: Use cloud-provider deployment diagrams

- Status: Accepted
- Date: 2026-07-21

## Context

The solution targets Azure and AWS. Readers need to understand the actual services, trust boundaries, network paths, governance controls, and cost-sensitive differences in each cloud. A provider-neutral diagram alone hides important implementation decisions.

## Decision

Use separate Azure and AWS architecture diagrams as the primary technical deployment views. Retain one small C4-style system context diagram for actors and external relationships.

Store editable diagram source as Mermaid in the documentation. Generated SVG or PNG exports may be produced for presentations, but they are derived artifacts.

## Consequences

- Cloud-specific designs are explicit and easier to review against provider guidance.
- Azure and AWS diagrams can evolve independently without implying false service equivalence.
- Some concepts appear in both diagrams, which creates intentional duplication at the presentation layer.
- Diagram reviews must accompany changes to Terraform resources, traffic flows, or security boundaries.

## Alternatives considered

### C4 diagrams only

Rejected as the sole standard because they do not emphasize provider services and deployment topology sufficiently for this training objective.

### One combined multi-cloud deployment diagram

Rejected because it becomes crowded and encourages misleading one-to-one comparisons between unlike cloud services.
