# Kubernetes Policy

## Blocked commands

| Command | Why |
|---------|-----|
| `kubectl delete namespace` | Deletes everything in the namespace - deployments, services, secrets, PVCs |
| `kubectl delete -f` | Can delete multiple resources at once from a manifest |
| `kubectl delete --all` | Bulk deletion across resource types |
| `kubectl drain --force` | Forcefully evicts pods, can cause downtime |
| `helm uninstall` / `helm delete` | Removes entire releases and their resources |

## What agents CAN do safely

- `kubectl get` - List/inspect resources
- `kubectl describe` - Detailed resource info
- `kubectl logs` - Read container logs
- `kubectl port-forward` - Local access to services
- `kubectl apply` - Create/update resources (with review)
- `kubectl scale` - Adjust replica count (with review)
- `helm list` - List releases
- `helm status` - Check release status
