resource "keycloak_group" "app" {
  realm_id = keycloak_realm.infrastructure.id
  name     = "app"
}

resource "keycloak_group" "app_admin" {
  realm_id  = keycloak_realm.infrastructure.id
  parent_id = keycloak_group.app.id
  name      = "admin"
}

resource "keycloak_group" "app_nextcloud" {
  realm_id  = keycloak_realm.infrastructure.id
  parent_id = keycloak_group.app.id
  name      = "nextcloud"
}
