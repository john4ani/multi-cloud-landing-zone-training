package terraform.security_test

import data.terraform.security
import rego.v1

test_allowed_plan_has_no_denials if {
  plan := {"resource_changes": [{
    "address": "aws_s3_bucket.frontend",
    "type": "aws_s3_bucket",
    "change": {"after": {"tags": {
      "application": "cloud-architecture-training",
      "environment": "training",
      "managed_by": "terraform",
      "owner": "training",
    }}},
  }]}
  denials := security.deny with input as plan
  count(denials) == 0
}

test_public_database_is_denied if {
  plan := {"resource_changes": [{
    "address": "aws_db_instance.training",
    "type": "aws_db_instance",
    "change": {"after": {"publicly_accessible": true}},
  }]}
  denials := security.deny with input as plan
  some message in denials
  contains(message, "must not be publicly accessible")
}
