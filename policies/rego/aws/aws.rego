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
  change.type in {"aws_nat_gateway", "aws_db_proxy", "aws_networkfirewall_firewall"}
  message := sprintf("%s is a paid component prohibited in the AWS training profile", [change.address])
}

deny contains message if {
  change := input.resource_changes[_]
  change.type == "aws_db_instance"
  not change.change.after.storage_encrypted
  message := sprintf("%s must encrypt database storage", [change.address])
}

deny contains message if {
  change := input.resource_changes[_]
  change.type == "aws_db_instance"
  not change.change.after.iam_database_authentication_enabled
  message := sprintf("%s must enable IAM database authentication", [change.address])
}

deny contains message if {
  change := input.resource_changes[_]
  change.type == "aws_db_instance"
  not change.change.after.instance_class in {"db.t4g.micro", "db.t3.micro"}
  message := sprintf("%s uses an unapproved training instance class", [change.address])
}

deny contains message if {
  change := input.resource_changes[_]
  change.type == "aws_db_instance"
  change.change.after.multi_az
  message := sprintf("%s enables paid Multi-AZ capacity in the training profile", [change.address])
}

deny contains message if {
  change := input.resource_changes[_]
  change.type == "aws_db_instance"
  change.change.after.max_allocated_storage > 0
  message := sprintf("%s enables unbounded storage autoscaling in the training profile", [change.address])
}

deny contains message if {
  change := input.resource_changes[_]
  change.type == "aws_vpc_security_group_ingress_rule"
  after := change.change.after
  after.from_port <= 5432
  after.to_port >= 5432
  object.get(after, "cidr_ipv4", null) != null
  message := sprintf("%s must reference the Lambda security group instead of a PostgreSQL CIDR", [change.address])
}

deny contains message if {
  change := input.resource_changes[_]
  change.type == "aws_lambda_function"
  change.change.after.reserved_concurrent_executions > 5
  message := sprintf("%s exceeds the training Lambda concurrency limit", [change.address])
}

deny contains message if {
  change := input.resource_changes[_]
  change.type == "aws_cloudfront_distribution"
  change.change.after.default_cache_behavior[_].viewer_protocol_policy != "redirect-to-https"
  message := sprintf("%s must redirect frontend viewers to HTTPS", [change.address])
}

deny contains message if {
  change := input.resource_changes[_]
  change.type == "aws_s3_bucket_public_access_block"
  not change.change.after.restrict_public_buckets
  message := sprintf("%s must restrict public buckets", [change.address])
}
