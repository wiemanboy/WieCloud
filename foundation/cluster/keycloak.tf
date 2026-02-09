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

resource "keycloak_group" "infra" {
  realm_id = keycloak_realm.infrastructure.id
  name     = "infra"
}

resource "keycloak_group" "infra_admin" {
  realm_id  = keycloak_realm.infrastructure.id
  parent_id = keycloak_group.infra.id
  name      = "admin"
}

resource "keycloak_group" "infra_harbor" {
  realm_id  = keycloak_realm.infrastructure.id
  parent_id = keycloak_group.infra.id
  name      = "harbor"
}

resource "keycloak_group" "infra_harbor_admin" {
  realm_id  = keycloak_realm.infrastructure.id
  parent_id = keycloak_group.infra_harbor.id
  name      = "admin"
}

resource "keycloak_group" "infra_keycloak" {
  realm_id  = keycloak_realm.infrastructure.id
  parent_id = keycloak_group.infra.id
  name      = "keycloak"
}

resource "keycloak_group" "infra_keycloak_admin" {
  realm_id  = keycloak_realm.infrastructure.id
  parent_id = keycloak_group.infra_keycloak.id
  name      = "admin"
}

resource "keycloak_user" "jarno_wieman" {
  realm_id       = keycloak_realm.infrastructure.id
  username       = "jarno_wieman"
  first_name     = "Jarno"
  last_name      = "Wieman"
  email          = "wiemanboy@gmail.com"
  email_verified = true
  enabled        = true
  initial_password {
    value = "temp"
  }
}

resource "keycloak_group_memberships" "jarno_wieman_infra_admin" {
  realm_id = keycloak_realm.infrastructure.id
  group_id = keycloak_group.infra_admin.id
  members  = [keycloak_user.jarno_wieman.username]
}

resource "keycloak_openid_client_scope" "client_scope" {
  realm_id = keycloak_realm.infrastructure.id
  name     = "groups"
}

resource "keycloak_openid_group_membership_protocol_mapper" "group_membership_mapper" {
  realm_id        = keycloak_realm.infrastructure.id
  client_scope_id = keycloak_openid_client_scope.client_scope.id
  name            = "group-membership-mapper"

  claim_name = "groups"
}

module "argocd_client" {
  source    = "./modules/keycloak/client"
  name      = "argocd-test"
  namespace = "argocd-test"
  realm_id  = keycloak_realm.infrastructure.id
  urls = {
    root     = "https://argo.${local.values.environment.hostname}"
    admin    = "https://argo.${local.values.environment.hostname}"
    base     = "https://argo.${local.values.environment.hostname}/applications"
    redirect = ["https://argo.${local.values.environment.hostname}/auth/callback"]
  }
}
