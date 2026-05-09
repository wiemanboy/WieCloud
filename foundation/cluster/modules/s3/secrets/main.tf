locals {
  identity_ns_pairs = flatten([
    for id in var.identities : [
      for ns in try(id.namespaces, [var.namespace]) : {
        key       = "${id.name}/${ns}"
        name      = id.name
        namespace = ns
        identity  = id
      }
    ]
  ])

  identity_ns_map = { for p in local.identity_ns_pairs : p.key => p }
}

resource "random_password" "access_key" {
  for_each = { for id in var.identities : id.name => id }
  length   = 20
  special  = false
}

resource "random_password" "secret_key" {
  for_each = { for id in var.identities : id.name => id }
  length   = 40
  special  = false
}

resource "kubernetes_secret_v1" "s3_config" {
  metadata {
    name      = var.name
    namespace = var.namespace
  }
  data = {
    "seaweedfs_s3_config.json" = jsonencode({
      identities = [
        for id in var.identities : {
          name    = id.name
          actions = id.actions
          credentials = [
            {
              accessKey = random_password.access_key[id.name].result
              secretKey = random_password.secret_key[id.name].result
            }
          ]
        }
      ]
    })
  }
}

resource "kubernetes_secret_v1" "s3_secret" {
  for_each = local.identity_ns_map
  metadata {
    name      = each.value.name
    namespace = each.value.namespace
  }
  data = {
    accessKey = random_password.access_key[each.value.name].result
    secretKey = random_password.secret_key[each.value.name].result
  }
}
