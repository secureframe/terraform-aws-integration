# Organization

Connects an AWS organization from one configuration: the Secureframe role in the management account and in two member accounts, with default options.

## Steps

1. In Secureframe, add an AWS connection. Choose **Connect AWS organization** and the account type: Commercial or GovCloud.
2. Copy the external ID.
3. In `main.tf`, replace the placeholders in `locals`: the external ID, the management account ID, and the two member account IDs. For GovCloud, also set `partition` to `aws-us-gov` and `region` to a GovCloud region such as `us-gov-west-1`.
4. Sign in to the **management account** with permission to create IAM roles and to assume `OrganizationAccountAccessRole` in the member accounts. AWS Organizations creates that role in accounts it creates. For accounts that joined by invitation, use a role or profile that exists in them instead.
5. Apply:

   ```bash
   terraform init
   ```

   ```bash
   terraform apply
   ```

   Each provider has `allowed_account_ids`, so the plan stops if any credentials lead to the wrong account.

6. Paste the `role_arn` output into the Role ARN field in Secureframe, select the member accounts, and finish the setup.

OpenTofu works the same way with `tofu init` and `tofu apply`.

## Adding a member account

Copy a member `provider` block and `module` block, give them a new alias and module name, set the account ID, and apply.

## Creates

| Account | Role | Extra permissions |
| ------- | ---- | ----------------- |
| Management | `SecureframeOrgRole-<id>` | `organizations:List*` and `sts:TagSession` |
| Each member | `SecureframeOrgRole-<id>` | none |

Every role has the AWS managed `SecurityAudit` policy and the `SecureframeAdditionalPermissions` inline policy. For GovCloud, sign in with GovCloud credentials; the `partition` and `region` locals set every provider region and ARN.

For custom role names, paths, permissions boundaries, managed policies, and tags, see the [advanced organization example](../organization-advanced).
