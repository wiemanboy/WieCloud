resource "keycloak_openid_client_scope" "client_scope" {
  realm_id = keycloak_realm.wiecloud.id
  name     = "groups"
}

resource "keycloak_openid_group_membership_protocol_mapper" "group_membership_mapper" {
  realm_id        = keycloak_realm.wiecloud.id
  client_scope_id = keycloak_openid_client_scope.client_scope.id
  name            = "group-membership-mapper"

  claim_name = "groups"
}

module "argocd_client" {
  source   = "./modules/keycloak/client"
  realm_id = keycloak_realm.wiecloud.id

  name      = "argocd"
  namespace = "argocd"

  urls = {
    root = "https://argo.${var.hostname}"
    base = "https://argo.${var.hostname}/applications"
    redirect = [
      "https://argo.${var.hostname}/auth/callback",
      "argocd://auth/callback"
    ]
  }
}

module "harbor_client" {
  source   = "./modules/keycloak/client"
  realm_id = keycloak_realm.wiecloud.id

  name      = "harbor"
  namespace = "harbor"

  urls = {
    root     = "https://harbor.${var.hostname}"
    redirect = ["https://harbor.${var.hostname}/c/oidc/callback"]
  }
}

module "nextcloud_client" {
  source   = "./modules/keycloak/client"
  realm_id = keycloak_realm.wiecloud.id

  name      = "nextcloud"
  namespace = "nextcloud"

  urls = {
    root                 = "https://next.${var.hostname}"
    redirect             = ["https://next.${var.hostname}/apps/user_oidc/code"]
    post_logout_redirect = ["https://next.${var.hostname}/"]
  }
}

module "grafana_client" {
  source   = "./modules/keycloak/client"
  realm_id = keycloak_realm.wiecloud.id

  name      = "grafana"
  namespace = "prometheus"

  urls = {
    root     = "https://grafana.${var.hostname}"
    redirect = ["https://grafana.${var.hostname}/login/generic_oauth"]
  }
}
