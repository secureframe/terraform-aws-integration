# Connects an AWS organization with every module option customized: the management account and two member accounts.
# Replace the placeholder IDs, sign in to the management account, and apply.

locals {
  # For GovCloud, use "aws-us-gov" and a GovCloud region such as "us-gov-west-1".
  partition = "aws"
  region    = "us-east-1"

  external_id           = "00000000-0000-0000-0000-000000000000"
  management_account_id = "111111111111"
  member_a_account_id   = "222222222222"
  member_b_account_id   = "333333333333"

  # Role to assume in each member account from the management account.
  member_access_role_name = "OrganizationAccountAccessRole"

  # Secureframe finds member roles by name and path, so every account must share these.
  role_settings = {
    role_name            = "secureframe-audit"
    role_path            = "/vendors/secureframe/"
    role_description     = "Read-only access for Secureframe compliance scans"
    max_session_duration = 7200
    policy_type          = "managed"
    tags = {
      owner      = "security"
      managed-by = "terraform"
    }
  }

  # The permissions boundary policy must already exist in every account.
  permissions_boundary_name = "VendorAccessBoundary"
}

provider "aws" {
  alias               = "management"
  region              = local.region
  allowed_account_ids = [local.management_account_id]
}

provider "aws" {
  alias               = "member_a"
  region              = local.region
  allowed_account_ids = [local.member_a_account_id]

  assume_role {
    role_arn     = "arn:${local.partition}:iam::${local.member_a_account_id}:role/${local.member_access_role_name}"
    session_name = "secureframe-setup"
  }
}

provider "aws" {
  alias               = "member_b"
  region              = local.region
  allowed_account_ids = [local.member_b_account_id]

  assume_role {
    role_arn     = "arn:${local.partition}:iam::${local.member_b_account_id}:role/${local.member_access_role_name}"
    session_name = "secureframe-setup"
  }
}

module "secureframe_management" {
  source    = "../.."
  providers = { aws = aws.management }

  external_id              = local.external_id
  account_type             = "management"
  role_name                = local.role_settings.role_name
  role_path                = local.role_settings.role_path
  role_description         = local.role_settings.role_description
  max_session_duration     = local.role_settings.max_session_duration
  policy_type              = local.role_settings.policy_type
  tags                     = local.role_settings.tags
  permissions_boundary_arn = "arn:${local.partition}:iam::${local.management_account_id}:policy/${local.permissions_boundary_name}"
}

module "secureframe_member_a" {
  source    = "../.."
  providers = { aws = aws.member_a }

  external_id              = local.external_id
  account_type             = "member"
  role_name                = local.role_settings.role_name
  role_path                = local.role_settings.role_path
  role_description         = local.role_settings.role_description
  max_session_duration     = local.role_settings.max_session_duration
  policy_type              = local.role_settings.policy_type
  tags                     = local.role_settings.tags
  permissions_boundary_arn = "arn:${local.partition}:iam::${local.member_a_account_id}:policy/${local.permissions_boundary_name}"
}

module "secureframe_member_b" {
  source    = "../.."
  providers = { aws = aws.member_b }

  external_id              = local.external_id
  account_type             = "member"
  role_name                = local.role_settings.role_name
  role_path                = local.role_settings.role_path
  role_description         = local.role_settings.role_description
  max_session_duration     = local.role_settings.max_session_duration
  policy_type              = local.role_settings.policy_type
  tags                     = local.role_settings.tags
  permissions_boundary_arn = "arn:${local.partition}:iam::${local.member_b_account_id}:policy/${local.permissions_boundary_name}"
}

output "role_arn" {
  description = "Paste into the Role ARN field in Secureframe."
  value       = module.secureframe_management.role_arn
}

output "managed_policy_arns" {
  description = "Customer managed policies created in each account."
  value = {
    management = module.secureframe_management.policy_arn
    member_a   = module.secureframe_member_a.policy_arn
    member_b   = module.secureframe_member_b.policy_arn
  }
}
