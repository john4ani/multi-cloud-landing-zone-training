data "aws_caller_identity" "current" {}

resource "random_string" "suffix" {
  length  = 8
  upper   = false
  special = false
}

resource "aws_s3_bucket" "state" {
  bucket = "cloud-training-tfstate-${data.aws_caller_identity.current.account_id}-${random_string.suffix.result}"
  tags   = var.tags
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

data "aws_iam_policy_document" "state_transport" {
  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.state.arn,
      "${aws_s3_bucket.state.arn}/*",
    ]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "state_transport" {
  bucket = aws_s3_bucket.state.id
  policy = data.aws_iam_policy_document.state_transport.json
}

locals {
  github_oidc_url = "https://token.actions.githubusercontent.com"
  state_key       = "cloud-architecture-training/aws/training/platform.tfstate"
  plan_subjects = var.configure_github_oidc ? [
    "${var.github_oidc_repository_subject}:pull_request",
    "${var.github_oidc_repository_subject}:ref:refs/heads/main",
    "${var.github_oidc_repository_subject}:environment:aws-training-plan",
  ] : []
}

resource "aws_iam_openid_connect_provider" "github" {
  count          = var.configure_github_oidc && var.create_github_oidc_provider ? 1 : 0
  url            = local.github_oidc_url
  client_id_list = ["sts.amazonaws.com"]
  tags           = var.tags
}

data "aws_iam_openid_connect_provider" "github" {
  count = var.configure_github_oidc && !var.create_github_oidc_provider ? 1 : 0
  url   = local.github_oidc_url
}

locals {
  github_oidc_provider_arn = var.configure_github_oidc ? (
    var.create_github_oidc_provider
    ? aws_iam_openid_connect_provider.github[0].arn
    : data.aws_iam_openid_connect_provider.github[0].arn
  ) : null
}

data "aws_iam_policy_document" "github_plan_trust" {
  count = var.configure_github_oidc ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [local.github_oidc_provider_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = local.plan_subjects
    }
  }
}

data "aws_iam_policy_document" "github_apply_trust" {
  count = var.configure_github_oidc ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [local.github_oidc_provider_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["${var.github_oidc_repository_subject}:environment:aws-training"]
    }
  }
}

resource "aws_iam_role" "github_plan" {
  count                = var.configure_github_oidc ? 1 : 0
  name                 = "cloud-training-github-plan"
  assume_role_policy   = data.aws_iam_policy_document.github_plan_trust[0].json
  max_session_duration = 3600
  tags                 = var.tags
}

resource "aws_iam_role" "github_apply" {
  count                = var.configure_github_oidc ? 1 : 0
  name                 = "cloud-training-github-apply"
  assume_role_policy   = data.aws_iam_policy_document.github_apply_trust[0].json
  max_session_duration = 3600
  tags                 = var.tags
}

resource "aws_iam_role_policy_attachment" "github_plan_view_only" {
  count      = var.configure_github_oidc ? 1 : 0
  role       = aws_iam_role.github_plan[0].name
  policy_arn = "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess"
}

data "aws_iam_policy_document" "github_apply_services" {
  count = var.configure_github_oidc ? 1 : 0

  statement {
    sid    = "ManageApprovedTrainingServices"
    effect = "Allow"
    actions = [
      "apigateway:*",
      "budgets:*",
      "cloudfront:*",
      "cloudwatch:*",
      "cognito-idp:*",
      "ec2:AssociateRouteTable",
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:CreateRouteTable",
      "ec2:CreateSecurityGroup",
      "ec2:CreateSubnet",
      "ec2:CreateTags",
      "ec2:CreateVpc",
      "ec2:DeleteRouteTable",
      "ec2:DeleteSecurityGroup",
      "ec2:DeleteSubnet",
      "ec2:DeleteTags",
      "ec2:DeleteVpc",
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeRouteTables",
      "ec2:DescribeSecurityGroupRules",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeVpcAttribute",
      "ec2:DescribeVpcs",
      "ec2:DisassociateRouteTable",
      "ec2:ModifySecurityGroupRules",
      "ec2:ModifySubnetAttribute",
      "ec2:ModifyVpcAttribute",
      "ec2:ReplaceRouteTableAssociation",
      "ec2:RevokeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupIngress",
      "lambda:*",
      "logs:*",
      "rds:*",
      "resourcegroupstaggingapi:GetResources",
      "sns:*",
    ]
    resources = ["*"]
  }

  statement {
    sid     = "ManageWorkloadFrontendBucket"
    effect  = "Allow"
    actions = ["s3:*"]
    resources = [
      "arn:aws:s3:::${var.workload_resource_prefix}-web-*",
      "arn:aws:s3:::${var.workload_resource_prefix}-web-*/*",
    ]
  }
}

resource "aws_iam_role_policy" "github_apply_services" {
  count  = var.configure_github_oidc ? 1 : 0
  name   = "approved-training-services"
  role   = aws_iam_role.github_apply[0].id
  policy = data.aws_iam_policy_document.github_apply_services[0].json
}

data "aws_iam_policy_document" "github_plan_state" {
  count = var.configure_github_oidc ? 1 : 0

  statement {
    sid       = "ListStateBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.state.arn]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = [local.state_key, "${local.state_key}.*"]
    }
  }

  statement {
    sid       = "ReadState"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.state.arn}/${local.state_key}"]
  }
}

resource "aws_iam_role_policy" "github_plan_state" {
  count  = var.configure_github_oidc ? 1 : 0
  name   = "terraform-state-read"
  role   = aws_iam_role.github_plan[0].id
  policy = data.aws_iam_policy_document.github_plan_state[0].json
}

data "aws_iam_policy_document" "github_apply_additional" {
  count = var.configure_github_oidc ? 1 : 0

  statement {
    sid       = "ListStateBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.state.arn]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = [local.state_key, "${local.state_key}.*"]
    }
  }

  statement {
    sid    = "ManageStateAndLock"
    effect = "Allow"
    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:PutObject",
    ]
    resources = [
      "${aws_s3_bucket.state.arn}/${local.state_key}",
      "${aws_s3_bucket.state.arn}/${local.state_key}.tflock",
    ]
  }

  statement {
    sid    = "ManageWorkloadExecutionRoles"
    effect = "Allow"
    actions = [
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:DeleteRolePolicy",
      "iam:GetRole",
      "iam:GetRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:ListRolePolicies",
      "iam:ListRoleTags",
      "iam:PutRolePolicy",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:UpdateAssumeRolePolicy",
    ]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.workload_resource_prefix}-*"]
  }

  statement {
    sid       = "PassWorkloadRolesToLambda"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.workload_resource_prefix}-*"]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["lambda.amazonaws.com"]
    }
  }

  statement {
    sid       = "CreateRequiredServiceLinkedRoles"
    effect    = "Allow"
    actions   = ["iam:CreateServiceLinkedRole"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "iam:AWSServiceName"
      values   = ["rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "github_apply_additional" {
  count  = var.configure_github_oidc ? 1 : 0
  name   = "terraform-state-and-workload-iam"
  role   = aws_iam_role.github_apply[0].id
  policy = data.aws_iam_policy_document.github_apply_additional[0].json
}

output "bucket_name" {
  value = aws_s3_bucket.state.bucket
}

output "aws_account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "github_plan_role_arn" {
  value = var.configure_github_oidc ? aws_iam_role.github_plan[0].arn : null
}

output "github_apply_role_arn" {
  value = var.configure_github_oidc ? aws_iam_role.github_apply[0].arn : null
}

output "github_oidc_repository_subject" {
  value = var.configure_github_oidc ? var.github_oidc_repository_subject : null
}
