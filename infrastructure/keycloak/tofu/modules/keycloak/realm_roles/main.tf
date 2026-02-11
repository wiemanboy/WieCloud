data "keycloak_openid_client" "realm_management_client" {
  realm_id  = var.realm_id
  client_id = "realm-management"
}

data "keycloak_role" "permission" {
  for_each  = toset(var.realm_permissions)
  realm_id  = var.realm_id
  client_id = data.keycloak_openid_client.realm_management_client.id
  name      = each.value
}

resource "keycloak_role" "realm_admin_role" {
  realm_id    = var.realm_id
  name        = var.name
  description = var.description
  composite_roles = [
    for role in data.keycloak_role.permission : role.id
  ]
}
