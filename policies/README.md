# Policy as Code

Rego policies evaluate Terraform plan JSON before apply. Common rules enforce ownership tags, private databases, private storage, and versioned container images; provider files hold Azure- and AWS-specific controls.

The Azure training profile additionally enforces cost-governance tags, SQL TLS 1.2, a SQL virtual-network rule, the `Microsoft.Sql` subnet service endpoint, single-IP temporary firewall rules, scale-to-zero Container Apps, the Azure SQL free limit with `AutoPause`, and the exclusion of paid NAT Gateway, Azure Firewall, and Private Endpoint resources.

Run locally after producing a plan:

```powershell
terraform show -json tfplan > tfplan.json
opa eval --data policies/rego --input tfplan.json "data.terraform.security.deny"
opa test policies/rego policies/tests
```

Policy violations return human-readable messages and fail CI. Exceptions must be time-bound, documented, and reviewed; no blanket bypass file is provided.
