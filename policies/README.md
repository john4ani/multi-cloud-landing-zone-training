# Policy as Code

Rego policies evaluate Terraform plan JSON before apply. Common rules enforce ownership tags, private databases, private storage, and versioned container images; provider files hold Azure- and AWS-specific controls.

Run locally after producing a plan:

```powershell
terraform show -json tfplan > tfplan.json
opa eval --data policies/rego --input tfplan.json "data.terraform.security.deny"
opa test policies/rego policies/tests
```

Policy violations return human-readable messages and fail CI. Exceptions must be time-bound, documented, and reviewed; no blanket bypass file is provided.
