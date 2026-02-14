resource "kubernetes_secret_v1" "oidc_client_secret" {
  metadata {
    name      = "${var.name}-client-secret"
    namespace = var.namespace
  }
  data = {
    secret = keycloak_openid_client.oidc_client.client_secret
  }
}

resource "keycloak_openid_client" "oidc_client" {
  access_type                     = "CONFIDENTIAL"
  realm_id                        = var.realm_id
  client_id                       = var.name
  name                            = var.name
  root_url                        = var.urls.root
  admin_url                       = coalesce(var.urls.admin, var.urls.root)
  base_url                        = coalesce(var.urls.base, var.urls.root)
  valid_redirect_uris             = var.urls.redirect
  valid_post_logout_redirect_uris = coalesce(var.urls.post_logout_redirect, [])
  standard_flow_enabled           = true
  direct_access_grants_enabled    = true
  service_accounts_enabled        = true
}

resource "keycloak_openid_client_default_scopes" "client_default_scopes" {
  realm_id  = var.realm_id
  client_id = keycloak_openid_client.oidc_client.id

  default_scopes = [
    "acr",
    "basic",
    "email",
    "groups",
    "profile",
    "roles",
    "web-origins"
  ]
}
