package terraform.security

import rego.v1

deny contains message if {
  change := input.resource_changes[_]
  change.type == "aws_s3_bucket_public_access_block"
  not change.change.after.block_public_policy
  message := sprintf("%s must block public bucket policies", [change.address])
}

deny contains message if {
  change := input.resource_changes[_]
  change.type == "aws_s3_bucket_public_access_block"
  not change.change.after.restrict_public_buckets
  message := sprintf("%s must restrict public buckets", [change.address])
}
