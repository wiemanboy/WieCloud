resource "random_password" "keycloak_db_password" {
  length           = 16
  special          = true
  override_special = "!@#$%&*()-_=+[]{}<>:?"
}

resource "kubernetes_secret_v1" "keycloak_db_secret" {
  metadata {
    name      = "keycloak-db-secret"
    namespace = "keycloak"
  }
  data = {
    username = "admin",
    password = random_password.keycloak_db_password.result
  }
}

resource "random_password" "nextcloud_db_password" {
  length           = 16
  special          = true
  override_special = "!@#$%&*()-_=+[]{}<>:?"
}

resource "kubernetes_secret_v1" "nextcloud_db_secret" {
  metadata {
    name      = "nextcloud-db-secret"
    namespace = "nextcloud"
  }
  data = {
    username = "admin",
    password = random_password.nextcloud_db_password.result
  }
}
