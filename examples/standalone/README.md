# Standalone account

Connects one AWS account to Secureframe. Use this for an account that is not connected as part of an organization.

## Steps

1. In Secureframe, add an AWS connection. Choose **Connect AWS account** and the account type: Commercial or GovCloud.
2. Copy the external ID.
3. In `main.tf`, replace the placeholders in `locals`: the external ID and the account ID. For GovCloud, also set `region` to a GovCloud region such as `us-gov-west-1`.
4. Sign in to the AWS account with permission to create IAM roles and policies. For GovCloud, use GovCloud credentials.
5. Apply:

   ```bash
   tofu init
   ```

   ```bash
   tofu apply
   ```

   `account_id` guards against applying with the wrong credentials: the AWS provider stops if they belong to any other account.

6. Paste the `role_arn` output into the Role ARN field in Secureframe and finish the setup.

With Terraform, run the same commands with `terraform`.

## Creates

- IAM role `SecureframeRole-<id>`, which Secureframe's AWS account can assume with your external ID
- The AWS managed `SecurityAudit` policy, attached to the role
- Inline policy `SecureframeAdditionalPermissions` with read actions `SecurityAudit` lacks

## Module block

```hcl
module "secureframe" {
  source  = "secureframe/integration/aws"
  version = "~> 1.0"

  external_id  = "00000000-0000-0000-0000-000000000000"
  account_type = "standalone"
}
```
