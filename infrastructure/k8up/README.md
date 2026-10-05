# k8up

## Backup targets

### Local

A local s3 target is automatically configured for backups.

### OVH

For OVH a user has to be created with appropriate S3 credentials.

1. Go to the OVH Cloud Manager
2. Go to `Public Cloud > Object Storage > Create an object container > User > Create new user`
3. Save the generated credentials.
4. Add the generated credentials to secret manager:
  Region: `eu-west-gra`
  Path: `wiecloud/backup/ovh/s3`
  Values: `access_key`, `secret_key`
5. Generate a random repo password and add it to secret manager:
  Region: `eu-west-gra`
  Path: `wiecloud/backup/ovh/password`
  Values: `password`
