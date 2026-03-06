# Incident: Terraform destroy wipes production database

**Source:** [How I dropped our production database with Claude Code](https://alexeyondata.substack.com/p/how-i-dropped-our-production-database) by Alexey Grigorev

**Date:** February 26, 2025

## What happened

An engineer was migrating a website to AWS using Claude Code and Terraform. The Terraform state file was on a different computer. Without state, `terraform plan` saw no existing infrastructure and proposed creating everything from scratch.

While retrieving old files, the agent unpacked an archived Terraform folder that contained state for the **production platform** (DataTalks.Club course management system). When the agent proposed `terraform destroy` to "clean up duplicate resources," the engineer approved it.

The command destroyed:
- Production RDS database (1.9M rows, 2.5 years of student submissions)
- VPC, ECS cluster, load balancers, bastion host
- All automated database snapshots

## Recovery

AWS support located a hidden snapshot not visible in the console. Full restoration took ~24 hours.

## What guardrails would have prevented this

### Hard blocks (would have stopped it entirely)

A `settings.json` deny rule:
```json
"Bash(command:terraform destroy*)"
"Bash(command:*terraform destroy*)"
```

A `terraform-guard.sh` hook matching `terraform destroy` and exiting with code 2.

### Soft protections (would have added friction)

- Terraform `deletion_protection = true` on the RDS instance
- Terraform `prevent_destroy = true` lifecycle rule
- Remote state backend (S3) instead of local state files
- `CLAUDE.md` instruction: "NEVER run terraform destroy"

## Key lesson

The engineer approved the destructive command because they didn't fully understand what it would destroy. Human-in-the-loop is not a reliable safety mechanism for infrastructure commands. Hard technical controls are required.
