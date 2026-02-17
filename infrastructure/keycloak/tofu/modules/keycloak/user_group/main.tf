resource "keycloak_group" "parent_group" {
  realm_id  = var.realm_id
  parent_id = var.parent_id
  name      = var.name
}

resource "keycloak_group" "admin_group" {
  realm_id  = var.realm_id
  parent_id = keycloak_group.parent_group.id
  name      = "admin"
}

resource "keycloak_group" "user_group" {
  realm_id  = var.realm_id
  parent_id = keycloak_group.parent_group.id
  name      = "user"
}
