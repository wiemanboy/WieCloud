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

  name        = "argocd"
  namespace   = "argocd"
  access_type = "CONFIDENTIAL"

  urls = {
    root     = "https://argo.${var.hostname}"
    base     = "https://argo.${var.hostname}/applications"
    redirect = ["https://argo.${var.hostname}/auth/callback"]
  }
}

module "grafana_client" {
  source   = "./modules/keycloak/client"
  realm_id = keycloak_realm.wiecloud.id

  name        = "grafana"
  namespace   = "prometheus"
  access_type = "CONFIDENTIAL"

  urls = {
    root     = "https://grafana.${var.hostname}"
    redirect = ["https://grafana.${var.hostname}/login/generic_oauth"]
  }
}

module "harbor_client" {
  source   = "./modules/keycloak/client"
  realm_id = keycloak_realm.wiecloud.id

  name        = "harbor"
  namespace   = "harbor"
  access_type = "CONFIDENTIAL"

  urls = {
    root     = "https://harbor.${var.hostname}"
    redirect = ["https://harbor.${var.hostname}/c/oidc/callback"]
  }
}

module "kubeapi_client" {
  source   = "./modules/keycloak/client"
  realm_id = keycloak_realm.wiecloud.id

  name        = "kubeapi"
  access_type = "PUBLIC"

  urls = {
    root = "http://localhost:8000"
    redirect = [
      "http://localhost:8000",
      "http://127.0.0.1:8000"
    ]
  }
}

module "longhorn_client" {
  source   = "./modules/keycloak/client"
  realm_id = keycloak_realm.wiecloud.id

  name        = "longhorn"
  namespace   = "longhorn-system"
  access_type = "CONFIDENTIAL"

  urls = {
    root     = "https://longhorn.${var.hostname}"
    redirect = ["https://longhorn.${var.hostname}/oauth2/callback"]
  }
}

module "nextcloud_client" {
  source   = "./modules/keycloak/client"
  realm_id = keycloak_realm.wiecloud.id

  name        = "nextcloud"
  namespace   = "nextcloud"
  access_type = "CONFIDENTIAL"

  urls = {
    root                 = "https://next.${var.hostname}"
    redirect             = ["https://next.${var.hostname}/apps/user_oidc/code"]
    post_logout_redirect = ["https://next.${var.hostname}/"]
  }
}

