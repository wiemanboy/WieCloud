# Cluster setup

1. Check if argo and cilium versions are up-to-date
2. Run `./setup.sh`

## Useful commands

```bash
kubectl port-forward -n argocd svc/argocd-server 8080:80
```

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```
