locals {
  commercial_external_id = "11111111-1111-1111-1111-111111111111"
  govcloud_external_id   = "22222222-2222-2222-2222-222222222222"
}

provider "aws" {
  alias   = "commercial"
  region  = "us-east-1"
  profile = "commercial"
}

provider "aws" {
  alias   = "govcloud"
  region  = "us-gov-west-1"
  profile = "govcloud"
}

module "secureframe_commercial" {
  source    = "../.."
  providers = { aws = aws.commercial }

  external_id = local.commercial_external_id
}

module "secureframe_govcloud" {
  source    = "../.."
  providers = { aws = aws.govcloud }

  external_id = local.govcloud_external_id
}

output "secureframe_commercial_role_arn" {
  description = "Paste into the commercial AWS connection in Secureframe."
  value       = module.secureframe_commercial.role_arn
}

output "secureframe_govcloud_role_arn" {
  description = "Paste into the GovCloud AWS connection in Secureframe."
  value       = module.secureframe_govcloud.role_arn
}
