# Organization with OpenTofu

Creates the Secureframe role in the management account and in any number of member accounts from one configuration. Requires OpenTofu 1.9 or later, which supports `for_each` on provider blocks. With Terraform, apply the [management](../management) and [member](../member) examples instead.

## Steps

1. In Secureframe, add an AWS connection. Choose **Connect AWS organization** and copy the external ID.
2. Sign in to the management account. The example reaches each member account through `OrganizationAccountAccessRole`.
3. List member accounts in `member_accounts`, for example in `terraform.tfvars`:

   ```hcl
   external_id = "00000000-0000-0000-0000-000000000000"

   member_accounts = {
     "222222222222" = { connected = true }
     "333333333333" = { connected = true }
   }
   ```

4. Apply:

   ```bash
   tofu init
   ```

   ```bash
   tofu apply
   ```

5. Paste the `secureframe_role_arn` output into the Role ARN field in Secureframe, select the member accounts to scan, and finish the setup.

## Disconnecting a member account

1. Set `connected = false` for the account and apply. This deletes its role.
2. Remove the account from `member_accounts` and apply again.

Removing an account in one step fails, because OpenTofu needs that account's provider to delete the role.
