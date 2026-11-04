variable "external_id" {
  description = "External ID from the Secureframe AWS connection setup. In an organization, use the same value in the management account and every member account."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.external_id))
    error_message = "external_id must be the 36-character UUID shown in Secureframe."
  }
}

variable "account_type" {
  description = "Where this role lives. \"standalone\" for an account connected on its own, \"management\" for the management account of a connected organization, \"member\" for a member account of that organization."
  type        = string
  default     = "standalone"

  validation {
    condition     = contains(["standalone", "management", "member"], var.account_type)
    error_message = "account_type must be \"standalone\", \"management\", or \"member\"."
  }
}

variable "role_name" {
  description = "Name of the IAM role. Defaults to SecureframeRole-<id> for a standalone account and SecureframeOrgRole-<id> in an organization, where <id> is the last segment of external_id. In an organization, the management account and every member account must use the same name."
  type        = string
  default     = null

  validation {
    condition     = var.role_name == null || can(regex("^[\\w+=,.@-]{1,64}$", var.role_name))
    error_message = "role_name must be 1-64 characters: letters, digits, and +=,.@_-"
  }
}

variable "role_path" {
  description = "Path for the IAM role and, when policy_type is \"managed\", the IAM policy. In an organization, the management account and every member account must use the same path, because the path is part of the role ARN Secureframe derives for each member account."
  type        = string
  default     = "/"

  validation {
    condition     = can(regex("^/([\\x21-\\x7E]+/)?$", var.role_path)) && length(var.role_path) <= 512
    error_message = "role_path must be \"/\" or start and end with a forward slash with at least one character between."
  }
}

variable "role_description" {
  description = "Description of the IAM role."
  type        = string
  default     = "Cross account access for Secureframe"
}

variable "permissions_boundary_arn" {
  description = "ARN of a permissions boundary to set on the IAM role, if your account requires one."
  type        = string
  default     = null
}

variable "max_session_duration" {
  description = "Maximum session duration for the IAM role, in seconds."
  type        = number
  default     = 3600

  validation {
    condition     = var.max_session_duration >= 3600 && var.max_session_duration <= 43200
    error_message = "max_session_duration must be between 3600 and 43200 seconds."
  }
}

variable "policy_type" {
  description = "How to grant the permissions SecurityAudit lacks. \"inline\" adds an inline role policy. \"managed\" creates a customer managed policy and attaches it, for accounts that do not allow inline policies."
  type        = string
  default     = "inline"

  validation {
    condition     = contains(["inline", "managed"], var.policy_type)
    error_message = "policy_type must be \"inline\" or \"managed\"."
  }
}

variable "tags" {
  description = "Tags applied to the IAM role and, when policy_type is \"managed\", the IAM policy."
  type        = map(string)
  default     = {}
}
