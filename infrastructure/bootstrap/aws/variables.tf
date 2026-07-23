variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "configure_github_oidc" {
  type        = bool
  default     = false
  description = "Create the GitHub Actions plan/apply roles, trust policies, and scoped permissions."
}

variable "create_github_oidc_provider" {
  type        = bool
  default     = true
  description = "Create the account-level GitHub OIDC provider. Set false when it already exists in this AWS account."
}

variable "github_oidc_repository_subject" {
  type        = string
  default     = ""
  description = "Exact GitHub OIDC repository segment, for example repo:owner/repository or repo:owner@owner-id/repository@repository-id."

  validation {
    condition = !var.configure_github_oidc || can(regex(
      "^repo:[^/:]+(?:@[0-9]+)?/[^/:]+(?:@[0-9]+)?$",
      var.github_oidc_repository_subject
    ))
    error_message = "github_oidc_repository_subject must be the exact repo:owner/repository segment, optionally including GitHub immutable owner and repository IDs."
  }
}

variable "workload_resource_prefix" {
  type        = string
  default     = "cloud-training"
  description = "Prefix of the workload IAM roles the GitHub apply role may manage and pass to Lambda."

  validation {
    condition     = can(regex("^[a-z0-9-]{3,32}$", var.workload_resource_prefix))
    error_message = "workload_resource_prefix must contain 3-32 lowercase letters, numbers, or hyphens."
  }
}

variable "tags" {
  type = map(string)
  default = {
    application = "cloud-architecture-training"
    environment = "bootstrap"
    managed_by  = "terraform"
    owner       = "training"
  }
}
