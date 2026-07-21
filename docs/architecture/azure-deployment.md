# Azure deployment architecture

Status: Accepted baseline

This is the initial low-cost Azure deployment. Exact service configuration must be confirmed through ADRs and a Terraform cost review before deployment.

![Azure low-cost landing-zone deployment](diagrams/azure-deployment.svg)

The editable SVG uses official Microsoft Azure architecture icons. A [PNG rendering](diagrams/azure-deployment.png) is also available for tools that do not display SVG.

## Trust and traffic decisions

- Only HTTPS application ingress is exposed to browser users.
- The browser authenticates with Microsoft Entra ID using Authorization Code with PKCE and sends a bearer access token to the API.
- The API validates the Entra issuer, audience, signature, expiry, and application roles.
- Azure SQL is never directly reachable from the browser.
- The low-cost profile uses `Selected networks`, explicit Container Apps egress firewall rules, managed identity, and token-based database access.
- The broad `Allow Azure services and resources to access this server` firewall rule is prohibited.
- Full private connectivity is an enterprise extension because private networking components can create charges.
- The deployment identity uses short-lived federation rather than stored Azure credentials.

## Items requiring an ADR

- Static Web Apps versus Storage/Front Door for Angular hosting.
- Container Apps versus Azure Functions for the ASP.NET Core API.
- Monitoring configuration that remains within the selected free allowance.
