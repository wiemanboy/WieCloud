# Cluster setup

1. Check if argo and cilium versions are up-to-date
2. Run `./setup.sh`
3. Switch to the mirrored DockerHub registry `docker.io/wiemanboy`
4. Deploy `longhorn` `cilium` and `externalsecrets`
5. Deploy secret
6. Deploy `envoygateway`, `certmanager`, `externaldns` and `k8up`
7. If PVC backups need to be restored:
    1. Enable restore mode for associated products
    2. Create PVCs and associated namespaces
    3. Deploy restores per product
8. Deploy `seaweedfs`
9. If s3 restores need to be done
    1. Run associated restore command per seaweedfs instance
10. Deploy `cnpg`
11. If cnpg restores need to be done
    1. Deploy cnpg cluster in restore mode
12. Deploy `keycloak`
13. Deploy remaining applications: `argocd`, `prometheus`, `harbor` `wireguard`
14. Enable backups and tofudeployer

## Useful commands

```bash
kubectl port-forward -n argocd svc/argocd-server 8080:80
```

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```
