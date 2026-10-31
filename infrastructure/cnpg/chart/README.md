# CNPG

## SeaweedFS

### Backups

A restore can be done by running the following command on the backup pod:

```sh
weed filer.copy -c 1 -concurrentChunks 2 -maxMB 4 /backup/buckets http://cnpg-backup-filer:8888/
```
