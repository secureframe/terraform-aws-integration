# Commercial and GovCloud accounts together

Connects a commercial AWS account and a GovCloud account from one configuration. Each is a separate Secureframe connection with its own external ID.

## Steps

1. In Secureframe, add two AWS connections: one with account type **Commercial**, one with **GovCloud**. Copy each external ID.
2. Set the `commercial_external_id` and `govcloud_external_id` values in `main.tf`, and point the `commercial` and `govcloud` AWS CLI profiles at the two accounts.
3. Apply:

   ```bash
   tofu init
   ```

   ```bash
   tofu apply
   ```

4. Paste `secureframe_commercial_role_arn` into the commercial connection and `secureframe_govcloud_role_arn` into the GovCloud connection.

With Terraform, run the same commands with `terraform`.
