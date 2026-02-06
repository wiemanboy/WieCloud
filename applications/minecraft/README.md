# Minecraft

## Backup restore

1. Disable auto sync on the minecraft application
2. Scale down minecraft deployment to 0 replicas
3. (optional) Set the `TARGET_BACKUP` env var in the cronjob to the desired backup
4. Create a job from the cronjob in argo
5. ReEnable auto sync
