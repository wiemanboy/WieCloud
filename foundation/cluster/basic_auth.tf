locals {
  basic_auth_namespaces = ["gateway", "longhorn-system"]
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
    password = local.env.basic_auth.password
  }
}
