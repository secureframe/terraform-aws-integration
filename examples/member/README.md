# Organization member account

Creates the Secureframe role in one member account of an AWS organization. Apply it once per member account you want Secureframe to scan, after or alongside the [management account example](../management).

Secureframe does not ask for member role ARNs. It builds each one from the management account's role ARN by swapping in the member account ID, so the role name and path here must match the management account's.

## Steps

1. Use the external ID from the organization connection you started for the management account.
2. Get credentials for the member account, either directly or by assuming a role from the management account.
3. Apply:

   ```bash
   terraform init
   ```

   With credentials for the member account:

   ```bash
   terraform apply -var 'external_id=<external ID>' -var 'account_id=<member account ID>'
   ```

   From the management account, through the role AWS Organizations creates in new accounts:

   ```bash
   terraform apply -var 'external_id=<external ID>' -var 'account_id=<member account ID>' -var 'assume_role_arn=arn:aws:iam::<member account ID>:role/OrganizationAccountAccessRole'
   ```

   For GovCloud, add `-var 'region=us-gov-west-1'`, use GovCloud credentials, and use `arn:aws-us-gov` in `assume_role_arn`.

   `account_id` guards against applying with the wrong credentials: the AWS provider stops if they belong to any other account.

4. Check that the `role_arn` output matches the management account's `role_arn` except for the account ID.
5. Repeat for each member account, using a separate state for each, for example a separate directory or workspace.

OpenTofu works the same way with `tofu init` and `tofu apply`. To manage the management account and several member accounts in one configuration, see the [organization example](../organization).

New member accounts are not covered automatically. Add this module to the process that creates accounts, for example an Account Factory for Terraform customization.

## Creates

- IAM role `SecureframeOrgRole-<id>`, which Secureframe's AWS account can assume with your external ID
- The AWS managed `SecurityAudit` policy, attached to the role
- Inline policy `SecureframeAdditionalPermissions` with read actions `SecurityAudit` lacks

## Module block

```hcl
module "secureframe" {
  source  = "secureframe/integration/aws"
  version = "~> 1.0"

  external_id  = "00000000-0000-0000-0000-000000000000"
  account_type = "member"
}
```
