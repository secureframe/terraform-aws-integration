# Grants Secureframe the same access as the CloudFormation templates in cloudformation/aws,
# using IAM resources only. The partition of the configured provider selects commercial or GovCloud.
# tests/shared_values.tftest.hcl fails when these values drift from shared/aws.json.

data "aws_partition" "current" {}

locals {
  secureframe_account_ids = {
    "aws"        = "728997465891"
    "aws-us-gov" = "220954880480"
  }

  additional_permissions = [
    "apprunner:ListAssociatedServicesForWebAcl",
    "cognito-idp:ListResourcesForWebACL",
    "ecr:Describe*",
    "ecs:GetTaskProtection",
    "elasticfilesystem:DescribeBackupPolicy",
    "elastictranscoder:ListPipelines",
    "es:ListVpcEndpoint*",
    "ses:GetEmailIdentity",
    "ses:ListEmailIdentities",
    "wafv2:GetLoggingConfiguration",
    "wafv2:GetWebACLForResource",
  ]

  management_permissions = ["organizations:List*"]

  is_management = var.account_type == "management"

  partition                 = data.aws_partition.current.partition
  secureframe_principal_arn = "arn:${local.partition}:iam::${local.secureframe_account_ids[local.partition]}:root"
  security_audit_policy_arn = "arn:${local.partition}:iam::aws:policy/SecurityAudit"

  # Secureframe finds a member account's role by putting the member account ID
  # into the management role ARN, so every role in an organization shares one name.
  id_suffix         = element(split("-", var.external_id), 4)
  default_role_name = var.account_type == "standalone" ? "SecureframeRole-${local.id_suffix}" : "SecureframeOrgRole-${local.id_suffix}"
  role_name         = coalesce(var.role_name, local.default_role_name)

  permissions_policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      local.is_management ? [{
        Sid      = "AccessToMemberAccountList"
        Effect   = "Allow"
        Action   = local.management_permissions
        Resource = "*"
      }] : [],
      [{
        Sid      = "PermissionsNotIncludedInSecurityAudit"
        Effect   = "Allow"
        Action   = local.additional_permissions
        Resource = "*"
      }],
    )
  })
}

resource "aws_iam_role" "secureframe" {
  name                 = local.role_name
  path                 = var.role_path
  description          = var.role_description
  permissions_boundary = var.permissions_boundary_arn
  max_session_duration = var.max_session_duration
  tags                 = var.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = local.secureframe_principal_arn }
      Action    = local.is_management ? ["sts:AssumeRole", "sts:TagSession"] : ["sts:AssumeRole"]
      Condition = { StringEquals = { "sts:ExternalId" = var.external_id } }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "security_audit" {
  role       = aws_iam_role.secureframe.name
  policy_arn = local.security_audit_policy_arn
}

resource "aws_iam_role_policy" "permissions" {
  count = var.policy_type == "inline" ? 1 : 0

  name   = "SecureframeAdditionalPermissions"
  role   = aws_iam_role.secureframe.id
  policy = local.permissions_policy
}

resource "aws_iam_policy" "permissions" {
  count = var.policy_type == "managed" ? 1 : 0

  name        = "${local.role_name}-AdditionalPermissions"
  path        = var.role_path
  description = "Read permissions Secureframe needs that SecurityAudit lacks"
  policy      = local.permissions_policy
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "permissions" {
  count = var.policy_type == "managed" ? 1 : 0

  role       = aws_iam_role.secureframe.name
  policy_arn = aws_iam_policy.permissions[0].arn
}
