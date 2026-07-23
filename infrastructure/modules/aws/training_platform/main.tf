data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_cloudfront_cache_policy" "optimized" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_cache_policy" "disabled" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_origin_request_policy" "api" {
  name = "Managed-AllViewerExceptHostHeader"
}

locals {
  unique_suffix           = substr(sha256("${data.aws_caller_identity.current.account_id}:${var.region}:${var.resource_prefix}"), 0, 8)
  api_function_name       = "${var.resource_prefix}-api"
  migration_function_name = "${var.resource_prefix}-database-migration"
  database_port           = 5432
  frontend_origin         = "https://${aws_cloudfront_distribution.frontend.domain_name}"
  api_gateway_origin      = trimprefix(aws_apigatewayv2_api.api.api_endpoint, "https://")
  cognito_issuer          = "https://cognito-idp.${var.region}.amazonaws.com/${aws_cognito_user_pool.users.id}"
  callback_urls           = distinct(concat(["${local.frontend_origin}/authentication/callback"], var.additional_callback_urls))
  logout_urls             = distinct(concat([local.frontend_origin], var.additional_logout_urls))
}

resource "aws_vpc" "workload" {
  cidr_block           = "10.30.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = merge(var.tags, { Name = "${var.resource_prefix}-vpc" })
}

resource "aws_subnet" "private" {
  count = 2

  vpc_id                  = aws_vpc.workload.id
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = cidrsubnet(aws_vpc.workload.cidr_block, 8, count.index + 1)
  map_public_ip_on_launch = false
  tags = merge(var.tags, {
    Name = "${var.resource_prefix}-private-${count.index + 1}"
    Tier = "private"
  })
}

resource "aws_route_table" "private" {
  count = 2

  vpc_id = aws_vpc.workload.id
  tags   = merge(var.tags, { Name = "${var.resource_prefix}-private-${count.index + 1}" })
}

resource "aws_route_table_association" "private" {
  count = 2

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_security_group" "lambda" {
  name_prefix = "${var.resource_prefix}-lambda-"
  description = "Lambda egress only to the training PostgreSQL security group"
  vpc_id      = aws_vpc.workload.id
  ingress     = []
  egress      = []
  tags        = merge(var.tags, { Name = "${var.resource_prefix}-lambda" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "database" {
  name_prefix = "${var.resource_prefix}-database-"
  description = "PostgreSQL ingress only from the training Lambda security group"
  vpc_id      = aws_vpc.workload.id
  ingress     = []
  egress      = []
  tags        = merge(var.tags, { Name = "${var.resource_prefix}-database" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_egress_rule" "lambda_to_database" {
  security_group_id            = aws_security_group.lambda.id
  referenced_security_group_id = aws_security_group.database.id
  from_port                    = local.database_port
  to_port                      = local.database_port
  ip_protocol                  = "tcp"
  description                  = "PostgreSQL only"
}

resource "aws_vpc_security_group_ingress_rule" "database_from_lambda" {
  security_group_id            = aws_security_group.database.id
  referenced_security_group_id = aws_security_group.lambda.id
  from_port                    = local.database_port
  to_port                      = local.database_port
  ip_protocol                  = "tcp"
  description                  = "PostgreSQL from Lambda only"
}

resource "aws_db_subnet_group" "database" {
  name       = "${var.resource_prefix}-database"
  subnet_ids = aws_subnet.private[*].id
  tags       = var.tags
}

resource "aws_db_parameter_group" "database" {
  name_prefix = "${var.resource_prefix}-postgres17-"
  family      = "postgres17"
  description = "TLS-only parameters for the training PostgreSQL database"
  tags        = var.tags

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_instance" "database" {
  identifier = "${var.resource_prefix}-postgres"

  engine         = "postgres"
  engine_version = "17"
  instance_class = var.database_instance_class

  allocated_storage     = var.database_allocated_storage
  max_allocated_storage = 0
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.database_name
  username = var.database_admin_username

  password_wo         = var.database_admin_password
  password_wo_version = var.database_admin_password_version

  db_subnet_group_name   = aws_db_subnet_group.database.name
  parameter_group_name   = aws_db_parameter_group.database.name
  vpc_security_group_ids = [aws_security_group.database.id]
  publicly_accessible    = false
  multi_az               = false
  network_type           = "IPV4"

  iam_database_authentication_enabled = true
  auto_minor_version_upgrade          = true
  apply_immediately                   = true
  backup_retention_period             = 0
  deletion_protection                 = false
  delete_automated_backups            = true
  skip_final_snapshot                 = true
  copy_tags_to_snapshot               = true
  performance_insights_enabled        = false
  monitoring_interval                 = 0

  tags = var.tags
}

resource "aws_s3_bucket" "frontend" {
  bucket_prefix = "${var.resource_prefix}-web-"
  force_destroy = true
  tags          = var.tags
}

resource "aws_s3_bucket_ownership_controls" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket                  = aws_s3_bucket.frontend.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  rule {
    id     = "expire-noncurrent-training-assets"
    status = "Enabled"
    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }

  depends_on = [aws_s3_bucket_versioning.frontend]
}

resource "aws_cloudfront_origin_access_control" "frontend" {
  name                              = "${var.resource_prefix}-frontend"
  description                       = "Signs CloudFront requests to the private Angular bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_response_headers_policy" "security" {
  name = "${var.resource_prefix}-security-headers-${local.unique_suffix}"

  security_headers_config {
    content_type_options { override = true }
    frame_options {
      frame_option = "DENY"
      override     = true
    }
    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }
    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      preload                    = true
      override                   = true
    }
  }
}

resource "aws_cloudfront_distribution" "frontend" {
  enabled         = true
  is_ipv6_enabled = true
  price_class     = "PriceClass_100"
  http_version    = "http2and3"
  comment         = "Cloud Architecture Training - destroy after use"

  origin {
    domain_name              = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id                = "frontend-s3"
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend.id
  }

  origin {
    domain_name = local.api_gateway_origin
    origin_id   = "api-gateway"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id           = "frontend-s3"
    viewer_protocol_policy     = "redirect-to-https"
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD", "OPTIONS"]
    compress                   = true
    cache_policy_id            = data.aws_cloudfront_cache_policy.optimized.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security.id
  }

  ordered_cache_behavior {
    path_pattern               = "/api/*"
    target_origin_id           = "api-gateway"
    viewer_protocol_policy     = "https-only"
    allowed_methods            = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods             = ["GET", "HEAD", "OPTIONS"]
    compress                   = true
    cache_policy_id            = data.aws_cloudfront_cache_policy.disabled.id
    origin_request_policy_id   = data.aws_cloudfront_origin_request_policy.api.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security.id
  }

  ordered_cache_behavior {
    path_pattern               = "/health"
    target_origin_id           = "api-gateway"
    viewer_protocol_policy     = "https-only"
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD", "OPTIONS"]
    compress                   = true
    cache_policy_id            = data.aws_cloudfront_cache_policy.disabled.id
    origin_request_policy_id   = data.aws_cloudfront_origin_request_policy.api.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security.id
  }

  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 0
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 0
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  tags = var.tags
}

data "aws_iam_policy_document" "frontend_bucket" {
  statement {
    sid     = "AllowCloudFrontReadOnly"
    effect  = "Allow"
    actions = ["s3:GetObject"]
    resources = [
      "${aws_s3_bucket.frontend.arn}/*"
    ]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.frontend.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  policy = data.aws_iam_policy_document.frontend_bucket.json
}

resource "aws_cognito_user_pool" "users" {
  name                     = "${var.resource_prefix}-users"
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]
  mfa_configuration        = "OPTIONAL"
  deletion_protection      = "INACTIVE"
  user_pool_tier           = "LITE"

  username_configuration {
    case_sensitive = false
  }

  software_token_mfa_configuration {
    enabled = true
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  password_policy {
    minimum_length                   = 12
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = 1
  }

  tags = var.tags
}

resource "aws_cognito_user_pool_client" "spa" {
  name                                 = "${var.resource_prefix}-spa"
  user_pool_id                         = aws_cognito_user_pool.users.id
  generate_secret                      = false
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["email", "openid", "profile"]
  supported_identity_providers         = ["COGNITO"]
  callback_urls                        = local.callback_urls
  logout_urls                          = local.logout_urls
  prevent_user_existence_errors        = "ENABLED"
  enable_token_revocation              = true
  access_token_validity                = 15
  id_token_validity                    = 15
  refresh_token_validity               = 1
  explicit_auth_flows                  = ["ALLOW_REFRESH_TOKEN_AUTH"]

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }
}

resource "aws_cognito_user_pool_domain" "users" {
  domain       = "${var.resource_prefix}-${local.unique_suffix}"
  user_pool_id = aws_cognito_user_pool.users.id
}

resource "aws_apigatewayv2_api" "api" {
  name          = "${var.resource_prefix}-api"
  protocol_type = "HTTP"

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${var.resource_prefix}-api"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId        = "$context.requestId"
      routeKey         = "$context.routeKey"
      status           = "$context.status"
      responseLength   = "$context.responseLength"
      integrationError = "$context.integrationErrorMessage"
    })
  }

  default_route_settings {
    detailed_metrics_enabled = false
    throttling_burst_limit   = 10
    throttling_rate_limit    = 5
  }

  tags = var.tags
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "api" {
  name               = "${var.resource_prefix}-api-execution"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  tags               = var.tags
}

resource "aws_iam_role" "migration" {
  name               = "${var.resource_prefix}-migration-execution"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  tags               = var.tags
}

data "aws_iam_policy_document" "api_execution" {
  statement {
    sid       = "WriteFunctionLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.api.arn}:*"]
  }

  statement {
    sid    = "ManageVpcNetworkInterfaces"
    effect = "Allow"
    actions = [
      "ec2:AssignPrivateIpAddresses",
      "ec2:CreateNetworkInterface",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeSubnets",
      "ec2:UnassignPrivateIpAddresses",
    ]
    resources = ["*"]
  }

  statement {
    sid     = "ConnectAsRuntimeDatabaseUser"
    effect  = "Allow"
    actions = ["rds-db:connect"]
    resources = [
      "arn:${data.aws_partition.current.partition}:rds-db:${var.region}:${data.aws_caller_identity.current.account_id}:dbuser:${aws_db_instance.database.resource_id}/${var.database_runtime_username}"
    ]
  }
}

data "aws_iam_policy_document" "migration_execution" {
  statement {
    sid       = "WriteFunctionLogs"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.migration.arn}:*"]
  }

  statement {
    sid    = "ManageVpcNetworkInterfaces"
    effect = "Allow"
    actions = [
      "ec2:AssignPrivateIpAddresses",
      "ec2:CreateNetworkInterface",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeSubnets",
      "ec2:UnassignPrivateIpAddresses",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "api" {
  name   = "${var.resource_prefix}-api-runtime"
  role   = aws_iam_role.api.id
  policy = data.aws_iam_policy_document.api_execution.json
}

resource "aws_iam_role_policy" "migration" {
  name   = "${var.resource_prefix}-migration-runtime"
  role   = aws_iam_role.migration.id
  policy = data.aws_iam_policy_document.migration_execution.json
}

resource "aws_cloudwatch_log_group" "api" {
  name              = "/aws/lambda/${local.api_function_name}"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "migration" {
  name              = "/aws/lambda/${local.migration_function_name}"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

resource "aws_lambda_function" "api" {
  function_name = local.api_function_name
  description   = "Cloud Architecture Training ASP.NET Core API"
  role          = aws_iam_role.api.arn
  runtime       = "dotnet10"
  handler       = "CloudArchitectureTraining.Api"
  architectures = ["x86_64"]

  filename         = var.lambda_package_path
  source_code_hash = filebase64sha256(var.lambda_package_path)

  memory_size                    = 512
  timeout                        = 30
  reserved_concurrent_executions = var.lambda_reserved_concurrency

  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      ASPNETCORE_ENVIRONMENT              = "Aws"
      Authentication__Enabled             = tostring(var.authentication_enabled)
      Authentication__Authority           = local.cognito_issuer
      Authentication__Audience            = aws_cognito_user_pool_client.spa.id
      ConnectionStrings__TrainingDatabase = "Host=${aws_db_instance.database.address};Port=${local.database_port};Database=${var.database_name};Username=${var.database_runtime_username};SSL Mode=VerifyFull;Root Certificate=/var/task/global-bundle.pem;Timeout=15;Command Timeout=30;Maximum Pool Size=4;Minimum Pool Size=0;Connection Idle Lifetime=60"
      Database__Provider                  = "PostgreSql"
      Database__UseAwsIamAuthentication   = "true"
    }
  }

  logging_config {
    log_format            = "JSON"
    application_log_level = "INFO"
    system_log_level      = "WARN"
  }

  tracing_config {
    mode = "PassThrough"
  }

  depends_on = [
    aws_iam_role_policy.api,
    aws_vpc_security_group_egress_rule.lambda_to_database
  ]

  tags = var.tags
}

resource "aws_lambda_function" "migration" {
  function_name = local.migration_function_name
  description   = "Explicit PostgreSQL schema migration and IAM runtime-user bootstrap"
  role          = aws_iam_role.migration.arn
  runtime       = "dotnet10"
  handler       = "CloudArchitectureTraining.Api::CloudArchitectureTraining.Api.Aws.DatabaseMigrationFunction::HandleAsync"
  architectures = ["x86_64"]

  filename         = var.lambda_package_path
  source_code_hash = filebase64sha256(var.lambda_package_path)

  memory_size                    = 512
  timeout                        = 180
  reserved_concurrent_executions = 1

  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      Database__Endpoint        = aws_db_instance.database.address
      Database__Port            = tostring(local.database_port)
      Database__Name            = var.database_name
      Database__AdminUsername   = var.database_admin_username
      Database__RuntimeUsername = var.database_runtime_username
      Database__RootCertificate = "/var/task/global-bundle.pem"
    }
  }

  logging_config {
    log_format            = "JSON"
    application_log_level = "INFO"
    system_log_level      = "WARN"
  }

  tracing_config {
    mode = "PassThrough"
  }

  depends_on = [
    aws_iam_role_policy.migration,
    aws_vpc_security_group_egress_rule.lambda_to_database
  ]

  tags = var.tags
}

resource "aws_apigatewayv2_integration" "api" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.api.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
  timeout_milliseconds   = 29000
}

resource "aws_apigatewayv2_authorizer" "cognito" {
  api_id           = aws_apigatewayv2_api.api.id
  name             = "cognito"
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]

  jwt_configuration {
    audience = [aws_cognito_user_pool_client.spa.id]
    issuer   = local.cognito_issuer
  }
}

resource "aws_apigatewayv2_route" "health" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "GET /health"
  target             = "integrations/${aws_apigatewayv2_integration.api.id}"
  authorization_type = "NONE"
}

resource "aws_apigatewayv2_route" "api_root" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "ANY /api"
  target             = "integrations/${aws_apigatewayv2_integration.api.id}"
  authorization_type = var.authentication_enabled ? "JWT" : "NONE"
  authorizer_id      = var.authentication_enabled ? aws_apigatewayv2_authorizer.cognito.id : null
}

resource "aws_apigatewayv2_route" "api_proxy" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "ANY /api/{proxy+}"
  target             = "integrations/${aws_apigatewayv2_integration.api.id}"
  authorization_type = var.authentication_enabled ? "JWT" : "NONE"
  authorizer_id      = var.authentication_enabled ? aws_apigatewayv2_authorizer.cognito.id : null
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowApiGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

resource "aws_sns_topic" "alerts" {
  name              = "${var.resource_prefix}-alerts"
  kms_master_key_id = "alias/aws/sns"
  tags              = var.tags
}

resource "aws_sns_topic_subscription" "email" {
  for_each = toset(var.alert_contact_emails)

  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = each.value
}

resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.resource_prefix}-lambda-errors"
  alarm_description   = "The training API Lambda reported an error."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  dimensions          = { FunctionName = aws_lambda_function.api.function_name }
  tags                = var.tags
}

resource "aws_cloudwatch_metric_alarm" "lambda_throttles" {
  alarm_name          = "${var.resource_prefix}-lambda-throttles"
  alarm_description   = "The bounded training API Lambda concurrency was exhausted."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  dimensions          = { FunctionName = aws_lambda_function.api.function_name }
  tags                = var.tags
}

resource "aws_cloudwatch_metric_alarm" "database_cpu" {
  alarm_name          = "${var.resource_prefix}-database-cpu"
  alarm_description   = "The training PostgreSQL instance exceeded 80 percent CPU."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  dimensions          = { DBInstanceIdentifier = aws_db_instance.database.identifier }
  tags                = var.tags
}

resource "aws_cloudwatch_metric_alarm" "database_storage" {
  alarm_name          = "${var.resource_prefix}-database-free-storage"
  alarm_description   = "The training PostgreSQL instance has less than 2 GiB free storage."
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 2147483648
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  dimensions          = { DBInstanceIdentifier = aws_db_instance.database.identifier }
  tags                = var.tags
}

resource "aws_budgets_budget" "training" {
  name         = "${var.resource_prefix}-monthly"
  budget_type  = "COST"
  limit_amount = tostring(var.monthly_budget_amount)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"
  tags         = var.tags

  dynamic "notification" {
    for_each = length(var.alert_contact_emails) > 0 ? {
      actual   = { type = "ACTUAL", threshold = 20 }
      forecast = { type = "FORECASTED", threshold = 100 }
    } : {}

    content {
      comparison_operator        = "GREATER_THAN"
      notification_type          = notification.value.type
      threshold                  = notification.value.threshold
      threshold_type             = "PERCENTAGE"
      subscriber_email_addresses = var.alert_contact_emails
    }
  }
}
