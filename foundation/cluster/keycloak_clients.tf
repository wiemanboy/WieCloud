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
  realm_id  = keycloak_realm.infrastructure.id

  name      = "argocd-test"
  namespace = "oidc-test"

  urls = {
    root     = "https://argo.${local.values.environment.hostname}"
    admin    = "https://argo.${local.values.environment.hostname}"
    base     = "https://argo.${local.values.environment.hostname}/applications"
    redirect = ["https://argo.${local.values.environment.hostname}/auth/callback"]
  }
}

module "harbor_client" {
  source    = "./modules/keycloak/client"
  realm_id  = keycloak_realm.infrastructure.id

  name      = "harbor-test"
  namespace = "oidc-test"

  urls = {
    root     = "https://harbor.${local.values.environment.hostname}"
    admin    = "https://harbor.${local.values.environment.hostname}"
    base     = "https://harbor.${local.values.environment.hostname}"
    redirect = ["https://harbor.${local.values.environment.hostname}/c/oidc/callback"]
  }
}
