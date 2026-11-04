mock_provider "aws" {
  override_data {
    target = data.aws_partition.current
    values = { partition = "aws" }
  }
}

variables {
  external_id = "11111111-2222-3333-4444-555555555555"
}

run "standalone_commercial" {
  command = plan

  assert {
    condition     = aws_iam_role.secureframe.name == "SecureframeRole-555555555555"
    error_message = "Default standalone role name must match the CloudFormation template."
  }

  assert {
    condition     = jsondecode(aws_iam_role.secureframe.assume_role_policy).Statement[0].Principal.AWS == "arn:aws:iam::728997465891:root"
    error_message = "Commercial role must trust the commercial Secureframe account."
  }

  assert {
    condition     = jsondecode(aws_iam_role.secureframe.assume_role_policy).Statement[0].Condition.StringEquals["sts:ExternalId"] == var.external_id
    error_message = "Trust policy must require the external ID."
  }

  assert {
    condition     = jsondecode(aws_iam_role.secureframe.assume_role_policy).Statement[0].Action == ["sts:AssumeRole"]
    error_message = "Standalone role must only allow sts:AssumeRole."
  }

  assert {
    condition     = aws_iam_role_policy_attachment.security_audit.policy_arn == "arn:aws:iam::aws:policy/SecurityAudit"
    error_message = "Role must have the commercial SecurityAudit policy."
  }

  assert {
    condition     = [for s in jsondecode(aws_iam_role_policy.permissions[0].policy).Statement : s.Sid] == ["PermissionsNotIncludedInSecurityAudit"]
    error_message = "Standalone role must not get management account permissions."
  }

  assert {
    condition     = length(aws_iam_policy.permissions) == 0 && length(aws_iam_role_policy_attachment.permissions) == 0
    error_message = "Inline policy type must not create a managed policy."
  }

  assert {
    condition     = aws_iam_role.secureframe.path == "/" && aws_iam_role.secureframe.max_session_duration == 3600 && aws_iam_role.secureframe.permissions_boundary == null
    error_message = "Role defaults changed."
  }
}

run "standalone_govcloud" {
  command = plan

  override_data {
    target = data.aws_partition.current
    values = { partition = "aws-us-gov" }
  }

  assert {
    condition     = jsondecode(aws_iam_role.secureframe.assume_role_policy).Statement[0].Principal.AWS == "arn:aws-us-gov:iam::220954880480:root"
    error_message = "GovCloud role must trust the GovCloud Secureframe account."
  }

  assert {
    condition     = aws_iam_role_policy_attachment.security_audit.policy_arn == "arn:aws-us-gov:iam::aws:policy/SecurityAudit"
    error_message = "GovCloud role must have the GovCloud SecurityAudit policy."
  }
}

run "management_govcloud" {
  command = plan

  variables {
    account_type = "management"
  }

  override_data {
    target = data.aws_partition.current
    values = { partition = "aws-us-gov" }
  }

  assert {
    condition     = aws_iam_role.secureframe.name == "SecureframeOrgRole-555555555555"
    error_message = "Default management role name must match the CloudFormation template."
  }

  assert {
    condition     = jsondecode(aws_iam_role.secureframe.assume_role_policy).Statement[0].Action == ["sts:AssumeRole", "sts:TagSession"]
    error_message = "Management role must allow sts:AssumeRole and sts:TagSession."
  }

  assert {
    condition     = [for s in jsondecode(aws_iam_role_policy.permissions[0].policy).Statement : s.Sid] == ["AccessToMemberAccountList", "PermissionsNotIncludedInSecurityAudit"]
    error_message = "Management role must be able to list member accounts."
  }
}

run "member_govcloud" {
  command = plan

  variables {
    account_type = "member"
  }

  override_data {
    target = data.aws_partition.current
    values = { partition = "aws-us-gov" }
  }

  assert {
    # Same default name as management_govcloud. OpenTofu cannot reference another run's outputs in an assertion.
    condition     = aws_iam_role.secureframe.name == "SecureframeOrgRole-555555555555"
    error_message = "Member role must share the management role's default name."
  }

  assert {
    condition     = jsondecode(aws_iam_role.secureframe.assume_role_policy).Statement[0].Principal.AWS == "arn:aws-us-gov:iam::220954880480:root"
    error_message = "Member role must trust the GovCloud Secureframe account."
  }

  assert {
    condition     = jsondecode(aws_iam_role.secureframe.assume_role_policy).Statement[0].Action == ["sts:AssumeRole"]
    error_message = "Member role must only allow sts:AssumeRole, like the StackSet member template."
  }

  assert {
    condition     = [for s in jsondecode(aws_iam_role_policy.permissions[0].policy).Statement : s.Sid] == ["PermissionsNotIncludedInSecurityAudit"]
    error_message = "Member role must not get management account permissions."
  }
}

run "customized_role" {
  command = plan

  variables {
    account_type             = "management"
    role_name                = "security-secureframe-audit"
    role_path                = "/vendors/"
    role_description         = "Secureframe audit access"
    permissions_boundary_arn = "arn:aws:iam::123456789012:policy/VendorBoundary"
    max_session_duration     = 7200
    policy_type              = "managed"
    tags                     = { team = "security" }
  }

  # OpenTofu's mock provider fills computed attributes with random strings, which fail ARN validation.
  override_resource {
    target = aws_iam_policy.permissions
    values = { arn = "arn:aws:iam::123456789012:policy/vendors/security-secureframe-audit-AdditionalPermissions" }
  }

  assert {
    condition     = aws_iam_role.secureframe.name == "security-secureframe-audit" && output.role_name == "security-secureframe-audit"
    error_message = "role_name must override the default."
  }

  assert {
    condition     = aws_iam_role.secureframe.path == "/vendors/" && aws_iam_policy.permissions[0].path == "/vendors/"
    error_message = "role_path must apply to the role and managed policy."
  }

  assert {
    condition     = aws_iam_role.secureframe.permissions_boundary == "arn:aws:iam::123456789012:policy/VendorBoundary"
    error_message = "permissions_boundary_arn must be set on the role."
  }

  assert {
    condition     = aws_iam_role.secureframe.max_session_duration == 7200 && aws_iam_role.secureframe.description == "Secureframe audit access"
    error_message = "max_session_duration and role_description must be set on the role."
  }

  assert {
    condition     = length(aws_iam_role_policy.permissions) == 0
    error_message = "Managed policy type must not create an inline policy."
  }

  assert {
    condition     = aws_iam_policy.permissions[0].name == "security-secureframe-audit-AdditionalPermissions" && aws_iam_role_policy_attachment.permissions[0].role == "security-secureframe-audit"
    error_message = "Managed policy must be created and attached to the role."
  }

  assert {
    condition     = [for s in jsondecode(aws_iam_policy.permissions[0].policy).Statement : s.Sid] == ["AccessToMemberAccountList", "PermissionsNotIncludedInSecurityAudit"]
    error_message = "Managed policy must carry the management account permissions."
  }

  assert {
    condition     = aws_iam_role.secureframe.tags["team"] == "security" && aws_iam_policy.permissions[0].tags["team"] == "security"
    error_message = "Tags must apply to the role and managed policy."
  }
}

run "rejects_malformed_external_id" {
  command = plan

  variables {
    external_id = "not-a-uuid"
  }

  expect_failures = [var.external_id]
}

run "rejects_unknown_account_type" {
  command = plan

  variables {
    account_type = "child"
  }

  expect_failures = [var.account_type]
}

run "rejects_empty_role_path_segment" {
  command = plan

  variables {
    role_path = "//"
  }

  expect_failures = [var.role_path]
}

run "rejects_short_session_duration" {
  command = plan

  variables {
    max_session_duration = 900
  }

  expect_failures = [var.max_session_duration]
}
