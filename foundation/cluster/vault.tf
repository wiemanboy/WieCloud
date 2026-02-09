locals {
  basic_auth_namespaces = ["gateway", "longhorn-system"]

  # TODO: Remove namespaces
  namespaces = ["gateway", "keycloak", "harbor", "longhorn-system", "argocd", "minecraft"]
  # TODO: Remove OIDC client secrets -> Moved to keycloak module
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

# TODO: Remove without actually deleting in the cluster
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

# TODO: Remove -> Moved to keycloak module
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

# TODO: Remove -> Moved to keycloak module
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

resource "kubernetes_secret_v1" "cloudflare-api-token" {
  metadata {
    name      = "cloudflare-api-token"
    namespace = "gateway"
  }
  data = {
    api-token = local.env.wiecloud.cloudflare.token
  }
}

resource "kubernetes_secret_v1" "curseforge-api-token" {
  metadata {
    name      = "curseforge-api-token"
    namespace = "minecraft"
  }
  data = {
    api-token = local.env.wiecloud.curseforge.token
  }
}
