resource "keycloak_group" "infra" {
  realm_id = keycloak_realm.infrastructure.id
  name     = "infra"
}

resource "keycloak_group" "infra_admin" {
  realm_id  = keycloak_realm.infrastructure.id
  parent_id = keycloak_group.infra.id
  name      = "admin"
}

resource "keycloak_group" "infra_harbor" {
  realm_id  = keycloak_realm.infrastructure.id
  parent_id = keycloak_group.infra.id
  name      = "harbor"
}

resource "keycloak_group" "infra_harbor_admin" {
  realm_id  = keycloak_realm.infrastructure.id
  parent_id = keycloak_group.infra_harbor.id
  name      = "admin"
}

resource "keycloak_group" "infra_keycloak" {
  realm_id  = keycloak_realm.infrastructure.id
  parent_id = keycloak_group.infra.id
  name      = "keycloak"
}

resource "keycloak_group" "infra_keycloak_admin" {
  realm_id  = keycloak_realm.infrastructure.id
  parent_id = keycloak_group.infra_keycloak.id
  name      = "admin"
}

resource "keycloak_user" "jarno_wieman" {
  realm_id       = keycloak_realm.infrastructure.id
  username       = "jarno_wieman"
  first_name     = "Jarno"
  last_name      = "Wieman"
  email          = "wiemanboy@gmail.com"
  email_verified = true
  enabled        = true
  initial_password {
    value = "temp"
  }
}

resource "keycloak_group_memberships" "jarno_wieman_infra_admin" {
  realm_id = keycloak_realm.infrastructure.id
  group_id = keycloak_group.infra_admin.id
  members  = [keycloak_user.jarno_wieman.username]
}

resource "keycloak_group_memberships" "jarno_wieman_infra_admin" {
  realm_id = keycloak_realm.infrastructure.id
  group_id = keycloak_group.infra_harbor_admin.id
  members  = [keycloak_user.jarno_wieman.username]
}

resource "keycloak_group_memberships" "jarno_wieman_infra_admin" {
  realm_id = keycloak_realm.infrastructure.id
  group_id = keycloak_group.infra_keycloak_admin.id
  members  = [keycloak_user.jarno_wieman.username]
}
