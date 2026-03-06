# Cloud Provider Policy

## Blocked commands by provider

### AWS
| Command | What it destroys |
|---------|-----------------|
| `ec2 terminate-instances` | Virtual machines |
| `rds delete-db-instance` | Database instances |
| `rds delete-db-cluster` | Database clusters |
| `rds delete-db-snapshot` | Database backups |
| `s3 rb` | S3 buckets |
| `s3 rm --recursive` | All objects in a bucket/prefix |
| `cloudformation delete-stack` | Entire CloudFormation stacks |
| `ecs delete-cluster` | Container clusters |
| `eks delete-cluster` | Kubernetes clusters |
| `lambda delete-function` | Lambda functions |
| `route53 delete-hosted-zone` | DNS zones |

### GCP
| Command | What it destroys |
|---------|-----------------|
| `compute instances delete` | VMs |
| `sql instances delete` | Cloud SQL databases |
| `container clusters delete` | GKE clusters |
| `projects delete` | Entire GCP projects |

### Azure
| Command | What it destroys |
|---------|-----------------|
| `vm delete` | Virtual machines |
| `sql db delete` | SQL databases |
| `group delete` | Entire resource groups |
| `aks delete` | Kubernetes clusters |

### DigitalOcean
| Command | What it destroys |
|---------|-----------------|
| `droplet delete` | Droplets |
| `database delete` | Managed databases |
| `kubernetes cluster delete` | K8s clusters |
| `volume delete` | Block storage volumes |

## What agents CAN do safely

Read-only commands across all providers:
- List resources
- Describe/inspect resources
- Check status and health
- View logs and metrics
- Generate cost reports
