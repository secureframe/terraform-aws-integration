variable "account_id" {
  description = "ID of the member account to create the role in. When assume_role_arn is set, this is the account that role belongs to. The AWS provider refuses to run in any other account."
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.account_id))
    error_message = "account_id must be a 12-digit AWS account ID."
  }
}

variable "external_id" {
  description = "External ID from the Secureframe AWS organization connection. The same value used in the management account."
  type        = string
}

variable "region" {
  description = "Region for the AWS provider. IAM is global, so any region in the account's partition works. Use a us-gov region for GovCloud."
  type        = string
  default     = "us-east-1"
}

variable "assume_role_arn" {
  description = "Role to assume in the member account, for example arn:aws:iam::222222222222:role/OrganizationAccountAccessRole. Leave null when your credentials are already for the member account."
  type        = string
  default     = null
}
