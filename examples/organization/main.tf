# Connects an AWS organization: the management account and two member accounts, with default options.
# Replace the placeholder IDs, sign in to the management account, and apply.

locals {
  # For GovCloud, use "aws-us-gov" and a GovCloud region such as "us-gov-west-1".
  partition = "aws"
  region    = "us-east-1"

  external_id           = "00000000-0000-0000-0000-000000000000"
  management_account_id = "111111111111"
  member_a_account_id   = "222222222222"
  member_b_account_id   = "333333333333"
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
    role_arn = "arn:${local.partition}:iam::${local.member_a_account_id}:role/OrganizationAccountAccessRole"
  }
}

provider "aws" {
  alias               = "member_b"
  region              = local.region
  allowed_account_ids = [local.member_b_account_id]

  assume_role {
    role_arn = "arn:${local.partition}:iam::${local.member_b_account_id}:role/OrganizationAccountAccessRole"
  }
}

module "secureframe_management" {
  source    = "../.."
  providers = { aws = aws.management }

  external_id  = local.external_id
  account_type = "management"
}

module "secureframe_member_a" {
  source    = "../.."
  providers = { aws = aws.member_a }

  external_id  = local.external_id
  account_type = "member"
}

module "secureframe_member_b" {
  source    = "../.."
  providers = { aws = aws.member_b }

  external_id  = local.external_id
  account_type = "member"
}

output "role_arn" {
  description = "Paste into the Role ARN field in Secureframe."
  value       = module.secureframe_management.role_arn
}
