# Cluster setup

1. Check if argo and cilium versions are up-to-date
2. Run `./setup.sh`
3. Switch to the mirrored DockerHub registry `docker.io/wiemanboy`
4. Deploy `longhorn` `cilium` and `externalsecrets`
5. Deploy secret store `aws-secret`; `kubectl create secret generic aws-secret --from-literal=accessKey=$access_key --from-literal=secretKey=$secret_key -n external-secrets`
6. Deploy `envoygateway`, `certmanager`, `externaldns`, `seaweedfs` and `k8up`
7. Deploy `cnpg`
8. If Backup restores need to be done
    1. Enable restore mode for associated products
    2. Create PVCs and associated namespaces
    3. Deploy restores per product
    4. If s3 restores need to be done
    5. Run associated restore command per seaweedfs instance
    6. Deploy cnpg clusters in restore mode
9. Deploy `keycloak`
10. Deploy remaining applications: `argocd`, `prometheus`, `harbor` `wireguard`
11. Enable backups and tofudeployer

## Useful commands

```bash
kubectl port-forward -n argocd svc/argocd-server 8080:80
```

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```
