resource "random_password" "keycloak-db-password" {
  length           = 16
  special          = true
  override_special = "!@#$%&*()-_=+[]{}<>:?"
}

resource "kubernetes_secret_v1" "keycloak-db-secret" {
  metadata {
    name      = "keycloak-db-secret"
    namespace = "keycloak"
  }
  data = {
    username = "admin",
    password = random_password.keycloak-db-password.result
  }
}

resource "keycloak_realm" "infrastructure" {
  realm        = "infrastructure-test"
  enabled      = true
  display_name = "Infrastructure-test"
}
