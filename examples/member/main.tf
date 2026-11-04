provider "aws" {
  region              = var.region
  allowed_account_ids = [var.account_id]

  # Reach the member account from the management account's credentials, if set.
  dynamic "assume_role" {
    for_each = var.assume_role_arn == null ? [] : [var.assume_role_arn]

    content {
      role_arn = assume_role.value
    }
  }
}

module "secureframe" {
  source = "../.."

  external_id  = var.external_id
  account_type = "member"
}

output "role_arn" {
  description = "Secureframe derives this ARN from the management account's role. You don't paste it anywhere."
  value       = module.secureframe.role_arn
}

output "role_name" {
  description = "Must match the management account's role name."
  value       = module.secureframe.role_name
}
