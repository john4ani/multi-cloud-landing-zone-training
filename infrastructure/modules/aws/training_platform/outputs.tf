output "api_function_name" {
  value = aws_lambda_function.api.function_name
}

output "api_gateway_endpoint" {
  value = aws_apigatewayv2_api.api.api_endpoint
}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.frontend.id
}

output "database_address" {
  value = aws_db_instance.database.address
}

output "database_name" {
  value = aws_db_instance.database.db_name
}

output "database_port" {
  value = aws_db_instance.database.port
}

output "database_runtime_username" {
  value = var.database_runtime_username
}

output "frontend_bucket_name" {
  value = aws_s3_bucket.frontend.bucket
}

output "frontend_hostname" {
  value = aws_cloudfront_distribution.frontend.domain_name
}

output "frontend_url" {
  value = "https://${aws_cloudfront_distribution.frontend.domain_name}"
}

output "migration_function_name" {
  value = aws_lambda_function.migration.function_name
}

output "user_pool_client_id" {
  value = aws_cognito_user_pool_client.spa.id
}

output "user_pool_domain" {
  value = aws_cognito_user_pool_domain.users.domain
}

output "user_pool_id" {
  value = aws_cognito_user_pool.users.id
}

output "authentication_authority" {
  value = local.cognito_issuer
}

output "authentication_enabled" {
  value = var.authentication_enabled
}

output "authentication_scope" {
  value = "openid profile email"
}

output "administrator_group_name" {
  value = aws_cognito_user_group.administrator.name
}

output "user_group_name" {
  value = aws_cognito_user_group.user.name
}

output "vpc_id" {
  value = aws_vpc.workload.id
}
