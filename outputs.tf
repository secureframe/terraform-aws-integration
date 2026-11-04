output "role_arn" {
  description = "Paste this into the Role ARN field in Secureframe. For an organization, use the management account's role ARN."
  value       = aws_iam_role.secureframe.arn
}

output "role_name" {
  description = "Name of the IAM role. In an organization, the management account and every member account use this name."
  value       = aws_iam_role.secureframe.name
}

output "account_type" {
  description = "\"standalone\", \"management\", or \"member\"."
  value       = var.account_type
}

output "partition" {
  description = "\"aws\" for commercial, \"aws-us-gov\" for GovCloud."
  value       = local.partition
}

output "policy_arn" {
  description = "ARN of the customer managed policy when policy_type is \"managed\", otherwise null."
  value       = var.policy_type == "managed" ? aws_iam_policy.permissions[0].arn : null
}
