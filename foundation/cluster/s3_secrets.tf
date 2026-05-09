module "backup_s3_secret" {
  source    = "./modules/s3/secrets"
  name      = "s3-config-secret"
  namespace = "k8up"
  identities = [
    {
      name       = "backup-s3-secret"
      namespaces = ["minecraft", "nextcloud", "harbor", "keycloak", "default"]
      actions    = ["Admin"]
    }
  ]
}
