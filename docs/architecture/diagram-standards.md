# Architecture diagram standards

Status: Accepted

## Decision

Cloud-provider architecture diagrams are the primary technical views for this project. Azure and AWS have separate deployment diagrams so that service boundaries, identity, networking, data flow, governance, and cost-sensitive components remain explicit.

A small C4-style system context view is retained because it explains users and external system relationships without coupling the explanation to either cloud.

## Required views

| View | Purpose | Update trigger |
|---|---|---|
| System context | Users, source repository, delivery system, and cloud boundaries | External actor or system relationship changes |
| Azure deployment | Azure resources, trust boundaries, traffic, identity, and optional enterprise extensions | Azure service or network design changes |
| AWS deployment | AWS resources, trust boundaries, traffic, identity, and optional enterprise extensions | AWS service or network design changes |
| Delivery and policy | Validation, approval, deployment, and runtime enforcement | Pipeline or policy enforcement changes |

## Conventions

- Solid lines represent active runtime or deployment flows.
- Dashed lines represent identity, governance, or optional enterprise extensions.
- Public, application, and data boundaries are visually separated.
- Every arrow states its protocol or purpose.
- Cost-sensitive optional resources are marked explicitly.
- Diagrams contain no credentials, account identifiers, subscription identifiers, or environment-specific secrets.
- Diagram source is stored with the documentation and reviewed with the related implementation.

## Rendering

Mermaid is used for logical diagrams where labeled nodes and edges are sufficient. Provider-specific diagrams use editable SVG with official Azure or AWS architecture icons stored beside the diagram. PNG files are generated compatibility artifacts and never replace the editable Mermaid or SVG source.
