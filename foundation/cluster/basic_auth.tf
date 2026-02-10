locals {
  username              = "admin"
  basic_auth_namespaces = ["gateway", "longhorn-system"]
}

resource "random_password" "basic_auth_password" {
  length = 20
}

resource "kubernetes_secret_v1" "basic_auth_secret" {
  for_each = { for ns in local.basic_auth_namespaces : ns => {} }
  type     = "kubernetes.io/basic-auth"
  metadata {
    name      = "server-auth-secret"
    namespace = each.key
  }
  data = {
    username = local.username,
    password = random_password.basic_auth_password.result
  }
}
