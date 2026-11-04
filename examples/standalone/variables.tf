variable "account_id" {
  description = "ID of the AWS account to create the role in. The AWS provider refuses to run with credentials for any other account."
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.account_id))
    error_message = "account_id must be a 12-digit AWS account ID."
  }
}

variable "external_id" {
  description = "External ID from the Secureframe AWS connection setup."
  type        = string
}

variable "region" {
  description = "Region for the AWS provider. IAM is global, so any region in the account's partition works. Use a us-gov region for GovCloud."
  type        = string
  default     = "us-east-1"
}
