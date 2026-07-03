# Cluster setup

## Rollout

1. Check if argo and cilium versions are up-to-date
2. Run `./setup.sh`
3. Switch to the mirrored DockerHub registry `docker.io/wiemanboy`, disable backups and set `tofudeployer` to `dryRun`
4. Deploy `longhorn` `cilium`, `externalsecrets` and `kyverno
5. Deploy aws secret for the secret store `aws-secret`; `kubectl create secret generic aws-secret --from-literal=accessKey=$access_key --from-literal=secretKey=$secret_key -n external-secrets`
6. Deploy `envoygateway`, `certmanager`, `externaldns`, `seaweedfs`, `k8up` and `cnpg`
7. (Optional) follow backup procedures
8. Deploy `keycloak`
9. Deploy remaining infrastructure: `argocd`, `prometheus`, `harbor` `wireguard`
10. Deploy the applications follow the backup procedures if necessary
11. Enable backups and `tofudeployer`
12. Done!

## Backup procedures

### PVC

1. Create the PVC used to restore the backup
2. Check in the S3 bucket wich snapshot you want to restore
3. Deploy the restore via the values

    ```yaml
    restores:
        - name: example-restore
        enabled: true
        fromBackup: local # Specify the backup source
        snapshot: "00000000" # 8 characters long
        claim:
            name: example-pvc
    ```

4. Wait for the restore to complete and check the logs of the restore pod
5. Done!

### SeaweedFS

1. Ensure the Seaweed cluster is running and healthy
2. Ensure the backups are available in the PVC
3. Deploy the restore job via the values

    ```yaml
    seaweedfs:
      backup:
        enabled: true
      restore:
        enabled: false
    ```

4. Wait for the restore to complete and check the logs of the restore pod
5. Done!

### CNPG

1. Make sure the CNPG cluster is **NOT** running
2. Ensure the backups are available in the S3 bucket
3. Deploy the CNPG cluster in restore mode via the values

    ```yaml
    cnpg:
      restore: true
    ```

4. Wait for the restore to complete and check the logs of the cnpg restore job
5. Done!

## Useful commands

```bash
kubectl port-forward -n argocd svc/argocd-server 8080:80
```

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```
