# CNPG

## SeaweedFS

### Backups

A restore can be done by running the following command on the backup pod:

```sh
weed filer.copy /backup/buckets http://backup-s3-filer:8888/
```
