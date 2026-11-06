# Secureframe AWS connection

Creates the read-only IAM role Secureframe assumes to scan an AWS account. Works with Terraform and OpenTofu, in commercial AWS and AWS GovCloud (US). The module reads the partition from your AWS provider, so the same code serves both.

The role has the same trust policy and permissions as the Secureframe CloudFormation templates. The module uses only IAM resources, and Secureframe needs nothing from AWS except the role ARN.

## Before you start

1. In Secureframe, add an AWS connection and choose the connection type (account or organization) and account type (Commercial or GovCloud).
2. Copy the external ID. Each Secureframe connection has its own, so a commercial account and a GovCloud account need separate IDs. The management account and every member account of one organization use the same ID.

## OpenTofu and Terraform

The configuration is the same for both tools: the same `source`, inputs, and outputs. Run `tofu init` and `tofu apply`, or the same commands with `terraform`. CI tests the module and every example with OpenTofu 1.12 and Terraform 1.9.

## Usage

Set `account_type` for where the role lives:

| Deployment | `account_type` | Paste into Secureframe | Example |
| ---------- | -------------- | ---------------------- | ------- |
| Single account | `standalone` | this role's ARN | [`examples/standalone`](examples/standalone) |
| Organization management account | `management` | this role's ARN | [`examples/management`](examples/management) |
| Organization member account | `member` | nothing; Secureframe derives it | [`examples/member`](examples/member) |

### Single account

```hcl
module "secureframe" {
  source  = "secureframe/integration/aws"
  version = "~> 1.0"

  external_id  = "00000000-0000-0000-0000-000000000000"
  account_type = "standalone"
}
```

### Organization management account

Apply in the management account.

```hcl
module "secureframe" {
  source  = "secureframe/integration/aws"
  version = "~> 1.0"

  external_id  = "00000000-0000-0000-0000-000000000000"
  account_type = "management"
}
```

### Organization member account

Apply in every member account you want scanned, with the same `external_id` as the management account. Secureframe builds each member role's ARN from the management role's ARN, so the role name and path must match. They do by default; if you set `role_name` or `role_path`, set the same values everywhere.

```hcl
module "secureframe" {
  source  = "secureframe/integration/aws"
  version = "~> 1.0"

  external_id  = "00000000-0000-0000-0000-000000000000"
  account_type = "member"
}
```

New member accounts are not covered automatically. Add the module to the process that creates accounts, for example an Account Factory for Terraform customization. If Secureframe is set to add new member accounts automatically, it can scan a new account only after the role exists there.

### GovCloud

Nothing changes in the module block. Configure the AWS provider with GovCloud credentials and a GovCloud region, and the module trusts Secureframe's GovCloud account.

```hcl
provider "aws" {
  region = "us-gov-west-1"
}
```

### More examples

| Example | Shows |
| ------- | ----- |
| [`organization`](examples/organization) | Management account and two member accounts in one configuration, default options |
| [`organization-advanced`](examples/organization-advanced) | The same, with a custom role name and path, permissions boundary, session duration, managed policy, and tags |
| [`commercial-and-govcloud`](examples/commercial-and-govcloud) | A commercial and a GovCloud account in one configuration |

Set `allowed_account_ids` on each AWS provider, as the examples do. The plan then stops before changing anything if the credentials belong to a different account.

## Finish in Secureframe

Run `apply`, then paste the role ARN into the Role ARN field in Secureframe. For an organization, paste the management account's role ARN.

## Inputs

| Name                       | Description                                                                                                  | Default                       |
| -------------------------- | ------------------------------------------------------------------------------------------------------------ | ----------------------------- |
| `external_id`              | External ID from the Secureframe connection setup. Required.                                                 | none                          |
| `account_type`             | `standalone`, `management`, or `member`.                                                                     | `standalone`                  |
| `role_name`                | IAM role name. In an organization, use the same name in every account.                                       | `SecureframeRole-<id>` standalone, `SecureframeOrgRole-<id>` in an organization |
| `role_path`                | Path for the role and managed policy. In an organization, use the same path in every account.                | `/`                           |
| `role_description`         | Role description.                                                                                            | `Cross account access for Secureframe` |
| `permissions_boundary_arn` | Permissions boundary for the role.                                                                           | `null`                        |
| `max_session_duration`     | Maximum session duration in seconds, 3600-43200.                                                             | `3600`                        |
| `policy_type`              | `inline` adds an inline policy. `managed` creates and attaches a customer managed policy.                    | `inline`                      |
| `tags`                     | Tags for the role and managed policy.                                                                        | `{}`                          |

`<id>` is the last segment of `external_id`.

## Outputs

| Name           | Description                                                  |
| -------------- | ------------------------------------------------------------ |
| `role_arn`     | Role ARN to paste into Secureframe.                          |
| `role_name`    | Role name. Every account in an organization uses it.         |
| `account_type` | `standalone`, `management`, or `member`.                     |
| `partition`    | `aws` or `aws-us-gov`.                                       |
| `policy_arn`   | Customer managed policy ARN when `policy_type` is `managed`. |

## Permissions granted

- The AWS managed `SecurityAudit` policy.
- `SecureframeAdditionalPermissions`: read actions that `SecurityAudit` lacks.
- The management account role also gets `organizations:List*` and `sts:TagSession`, so Secureframe can list member accounts.

Only Secureframe's AWS account can assume the role (`728997465891` commercial, `220954880480` GovCloud), and only with your external ID.

## Support

Secureframe publishes this module from an internal repository, so pull requests here are not merged. For questions or problems, contact Secureframe support.

## License

Apache 2.0. See [LICENSE](LICENSE).
