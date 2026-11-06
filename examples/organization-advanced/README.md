# Organization with custom options

Connects an AWS organization from one configuration, the management account and two member accounts, using every option the module offers. Start from the [organization example](../organization) if the defaults work for you.

## Options used

| Option | Value in this example | Why you might set it |
| ------ | --------------------- | -------------------- |
| `role_name` | `secureframe-audit` | Your account follows an IAM naming convention |
| `role_path` | `/vendors/secureframe/` | You group third-party roles under a path |
| `role_description` | custom text | Your IAM inventory requires descriptions |
| `permissions_boundary_arn` | `VendorAccessBoundary` in each account | Your organization requires a boundary on every role |
| `max_session_duration` | `7200` | Your policy sets session length for vendor roles |
| `policy_type` | `managed` | Your organization does not allow inline policies |
| `tags` | `owner`, `managed-by` | Your tagging policy requires them |

`role_name` and `role_path` must be the same in every account. Secureframe builds each member account's role ARN from the management role's ARN, including the name and path. The example keeps them in `local.role_settings` so the accounts can't drift apart.

## Steps

1. In Secureframe, add an AWS connection. Choose **Connect AWS organization** and the account type: Commercial or GovCloud.
2. In `main.tf`, replace the placeholders in `locals`: the external ID, the account IDs, the member access role, and the permissions boundary policy name. For GovCloud, also set `partition` to `aws-us-gov` and `region` to a GovCloud region such as `us-gov-west-1`; every provider region and ARN uses them. The boundary policy must already exist in every account and allow the permissions the role needs; otherwise remove `permissions_boundary_arn`.
3. Sign in to the **management account** with permission to create IAM roles and policies and to assume the member access role.
4. Apply:

   ```bash
   tofu init
   ```

   ```bash
   tofu apply
   ```

5. Paste the `role_arn` output, `arn:<partition>:iam::<management account ID>:role/vendors/secureframe/secureframe-audit`, into the Role ARN field in Secureframe, select the member accounts, and finish the setup.

With Terraform, run the same commands with `terraform`.

## Creates in each account

- IAM role `/vendors/secureframe/secureframe-audit` with the permissions boundary, a 2-hour maximum session, and the tags
- The AWS managed `SecurityAudit` policy, attached to the role
- Customer managed policy `/vendors/secureframe/secureframe-audit-AdditionalPermissions`, attached to the role. In the management account it also grants `organizations:List*`.
