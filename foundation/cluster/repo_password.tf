locals {
  repo_secret_namespaces = ["minecraft", "nextcloud", "harbor", "keycloak", "default"]
}

resource "kubernetes_secret_v1" "repo_password_secret" {
  for_each = { for ns in local.repo_secret_namespaces : ns => {} }
  metadata {
    name      = "repo-password-secret"
    namespace = each.key
  }
  data = {
    password = local.env.backup.repo.password
  }
}
