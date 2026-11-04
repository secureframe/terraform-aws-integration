provider "aws" {
  region              = var.region
  allowed_account_ids = [var.account_id]
}

module "secureframe" {
  source = "../.."

  external_id  = var.external_id
  account_type = "management"
}

output "role_arn" {
  description = "Paste into the Role ARN field in Secureframe."
  value       = module.secureframe.role_arn
}

output "role_name" {
  description = "Every member account must use this role name."
  value       = module.secureframe.role_name
}
