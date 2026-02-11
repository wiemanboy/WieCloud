resource "kubernetes_secret_v1" "cloudflare-api-token" {
  metadata {
    name      = "cloudflare-api-token"
    namespace = "gateway"
  }
  data = {
    api-token = local.env.api_tokens.cloudflare.token
  }
}

resource "kubernetes_secret_v1" "curseforge-api-token" {
  metadata {
    name      = "curseforge-api-token"
    namespace = "minecraft"
  }
  data = {
    api-token = local.env.api_tokens.curseforge.token
  }
}
