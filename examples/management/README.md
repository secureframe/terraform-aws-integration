# Organization management account

Creates the Secureframe role in the management account of an AWS organization. Secureframe uses this role to list the organization's member accounts, and connects to each member account through a role with the same name. Create those roles with the [member account example](../member), or manage every account in one configuration with the [organization example](../organization).

## Steps

1. In Secureframe, add an AWS connection. Choose **Connect AWS organization** and the account type: Commercial or GovCloud.
2. Copy the external ID. You use the same external ID in the management account and every member account.
3. Sign in to the **management account** with permission to create IAM roles and policies.
4. Apply:

   ```bash
   terraform init
   ```

   ```bash
   terraform apply -var 'external_id=<external ID>' -var 'account_id=<account ID>'
   ```

   For GovCloud, add `-var 'region=us-gov-west-1'` and use GovCloud credentials.

   `account_id` guards against applying with the wrong credentials: the AWS provider stops if they belong to any other account.

5. Create the role in each member account with the [member account example](../member), using the same external ID.
6. Paste the `role_arn` output from this example into the Role ARN field in Secureframe, select the member accounts to scan, and finish the setup.

OpenTofu works the same way with `tofu init` and `tofu apply`.

## Creates

- IAM role `SecureframeOrgRole-<id>`, which Secureframe's AWS account can assume with your external ID. The trust policy also allows `sts:TagSession`.
- The AWS managed `SecurityAudit` policy, attached to the role
- Inline policy `SecureframeAdditionalPermissions` with read actions `SecurityAudit` lacks, plus `organizations:List*` to list member accounts

## Module block

```hcl
module "secureframe" {
  source  = "secureframe/integration/aws"
  version = "~> 1.0"

  external_id  = "00000000-0000-0000-0000-000000000000"
  account_type = "management"
}
```

If you set `role_name` or `role_path`, set the same values in every member account.
