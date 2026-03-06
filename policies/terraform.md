# Terraform Policy

## Blocked commands

| Command | Why |
|---------|-----|
| `terraform destroy` | Deletes all managed infrastructure. No partial targeting is safe enough for an agent. |
| `terraform apply -auto-approve` | Skips the interactive review step. Agents should never auto-approve. |
| `terraform state rm` | Removes resources from state without destroying them, causing drift and orphaned resources. |
| `terraform state push` | Overwrites remote state. Can cause catastrophic state corruption. |
| `terraform force-unlock` | Bypasses state locking. Can cause concurrent modifications and state corruption. |

Also covers OpenTofu (`tofu`), Terragrunt (`terragrunt`), and Pulumi equivalents.

## What agents CAN do safely

- `terraform init` - Initialize providers and modules
- `terraform plan` - Preview changes (read-only)
- `terraform validate` - Check configuration syntax
- `terraform fmt` - Format configuration files
- `terraform output` - Read output values
- `terraform show` - Inspect current state (read-only)
- `terraform state list` - List resources in state (read-only)

## Recommended Terraform configuration

Always set these on critical resources:

```hcl
resource "aws_db_instance" "production" {
  # ...
  deletion_protection = true

  lifecycle {
    prevent_destroy = true
  }
}
```

## Remote state

Never use local state files for production infrastructure. Use a remote backend:

```hcl
terraform {
  backend "s3" {
    bucket         = "your-terraform-state"
    key            = "production/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

This prevents the state file from being lost, overwritten, or confused between machines - which is exactly what caused the DataTalks.Club incident.
