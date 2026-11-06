# Connects one AWS account.
# Replace the placeholder IDs, sign in to the account, and apply.

locals {
  # For GovCloud, use a GovCloud region such as "us-gov-west-1".
  region = "us-east-1"

  external_id = "00000000-0000-0000-0000-000000000000"
  account_id  = "111111111111"
}

provider "aws" {
  region              = local.region
  allowed_account_ids = [local.account_id]
}

module "secureframe" {
  source = "../.."

  external_id  = local.external_id
  account_type = "standalone"
}

output "role_arn" {
  description = "Paste into the Role ARN field in Secureframe."
  value       = module.secureframe.role_arn
}
