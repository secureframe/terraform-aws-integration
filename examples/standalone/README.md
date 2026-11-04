# Standalone account

Connects one AWS account to Secureframe. Use this for an account that is not connected as part of an organization.

## Steps

1. In Secureframe, add an AWS connection. Choose **Connect AWS account** and the account type: Commercial or GovCloud.
2. Copy the external ID.
3. Sign in to the AWS account with permission to create IAM roles and policies.
4. Apply:

   ```bash
   terraform init
   ```

   ```bash
   terraform apply -var 'external_id=<external ID>' -var 'account_id=<account ID>'
   ```

   For GovCloud, add `-var 'region=us-gov-west-1'` and use GovCloud credentials.

   `account_id` guards against applying with the wrong credentials: the AWS provider stops if they belong to any other account.

5. Paste the `role_arn` output into the Role ARN field in Secureframe and finish the setup.

OpenTofu works the same way with `tofu init` and `tofu apply`.

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
