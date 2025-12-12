locals {
  namespaces            = ["gateway", "keycloak", "harbor", "longhorn-system"]
  basic_auth_namespaces = ["gateway", "longhorn-system"]
  oidc = {
    harbor-client-secret = {
      namespace = "harbor"
      secret    = local.env.wiecloud.harbor.oidc.secret
    },
    argo-client-secret = {
      namespace = "argocd"
      secret    = local.env.wiecloud.argocd.oidc.secret
    }
  }
}

resource "kubernetes_namespace_v1" "namespace" {
  for_each = { for ns in local.namespaces : ns => {} }
  metadata {
    name = each.key
  }
  lifecycle {
    ignore_changes = all
  }
}

resource "kubernetes_secret_v1" "server-auth-secret" {
  for_each = { for ns in local.basic_auth_namespaces : ns => {} }
  type     = "kubernetes.io/basic-auth"
  metadata {
    name      = "server-auth-secret"
    namespace = each.key
  }
  data = {
    username = "admin",
    password = local.env.wiecloud.basic-auth.password
  }
}

resource "kubernetes_secret_v1" "oidc-client-secret" {
  for_each = local.oidc
  metadata {
    name      = each.key
    namespace = each.value.namespace
  }
  data = {
    secret = each.value.secret
  }
}

resource "kubernetes_secret_v1" "oidc-client-secret-keycloak" {
  for_each = local.oidc
  metadata {
    name      = each.key
    namespace = "keycloak"
  }
  data = {
    secret = each.value.secret
  }
}

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

resource "kubernetes_secret_v1" "cloudflare-api-token" {
  metadata {
    name = "cloudflare-api-token"
    namespace = "gateway"
  }
  data = {
    api-token = local.env.wiecloud.cloudflare.token
  }
}
