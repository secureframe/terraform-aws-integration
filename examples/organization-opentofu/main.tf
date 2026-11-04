# OpenTofu 1.9 or later. Connects an AWS organization with one provider per member account created by for_each.
# Terraform does not support for_each on provider blocks; use examples/organization instead.
#
# To disconnect a member account, set connected = false and apply, which deletes its role.
# Only then remove the account from member_accounts. Removing it in one step fails, because
# OpenTofu needs the account's provider to delete the role.

variable "external_id" {
  description = "External ID from the Secureframe organization connection."
  type        = string
  default     = "00000000-0000-0000-0000-000000000000"
}

variable "member_accounts" {
  description = "Member accounts, keyed by account ID. Values must be known before plan."
  type = map(object({
    connected = bool
  }))
  default = {
    "222222222222" = { connected = true }
    "333333333333" = { connected = true }
  }
}

provider "aws" {
  alias  = "management"
  region = "us-east-1"
}

provider "aws" {
  alias    = "member"
  for_each = var.member_accounts
  region   = "us-east-1"

  assume_role {
    role_arn = "arn:aws:iam::${each.key}:role/OrganizationAccountAccessRole"
  }
}

module "secureframe_management" {
  source    = "../.."
  providers = { aws = aws.management }

  external_id  = var.external_id
  account_type = "management"
}

module "secureframe_member" {
  source    = "../.."
  for_each  = { for account_id, account in var.member_accounts : account_id => account if account.connected }
  providers = { aws = aws.member[each.key] }

  external_id  = var.external_id
  account_type = "member"
}

output "secureframe_role_arn" {
  description = "Paste the management account's role ARN into the Role ARN field in Secureframe."
  value       = module.secureframe_management.role_arn
}
