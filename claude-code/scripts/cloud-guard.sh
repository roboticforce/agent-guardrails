#!/bin/bash
# cloud-guard.sh - Block destructive cloud provider commands
# Covers AWS, GCP, Azure, DigitalOcean
# Exit 0 = allow, Exit 2 = block (message shown to user)

INPUT=$(cat -)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
  exit 0
fi

BLOCKED_PATTERNS=(
  # AWS
  "aws ec2 terminate-instances"
  "aws rds delete-db-instance"
  "aws rds delete-db-cluster"
  "aws rds delete-db-snapshot"
  "aws s3 rb "
  "aws s3 rm.*--recursive"
  "aws cloudformation delete-stack"
  "aws ecs delete-cluster"
  "aws ecs delete-service"
  "aws eks delete-cluster"
  "aws lambda delete-function"
  "aws elasticache delete"
  "aws route53 delete-hosted-zone"
  # GCP
  "gcloud compute instances delete"
  "gcloud sql instances delete"
  "gcloud container clusters delete"
  "gcloud projects delete"
  "gcloud app services delete"
  # Azure
  "az vm delete"
  "az sql db delete"
  "az sql server delete"
  "az group delete"
  "az aks delete"
  "az webapp delete"
  # DigitalOcean
  "doctl droplet delete"
  "doctl database delete"
  "doctl kubernetes cluster delete"
  "doctl volume delete"
  # Generic
  "dd if=.*of=/dev/"
  "mkfs\."
  "fdisk "
)

for pattern in "${BLOCKED_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qiE "$pattern"; then
    echo "BLOCKED by agent-guardrails: Destructive cloud command detected." >&2
    echo "" >&2
    echo "  Command: $COMMAND" >&2
    echo "  Pattern: $pattern" >&2
    echo "" >&2
    echo "Cloud resource destruction must be run manually by a human." >&2
    echo "See: https://github.com/roboticforce/agent-guardrails" >&2
    exit 2
  fi
done

exit 0
