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

module "realm_admin_role" {
  source   = "./modules/keycloak/realm_roles"
  realm_id = keycloak_realm.infrastructure.id

  name        = "admin"
  description = "Admin role for the realm"

  realm_permissions = [
    "view-clients",
    "manage-realm",
    "view-users",
    "create-client",
    "manage-users",
    "query-users",
    "view-identity-providers",
    "manage-identity-providers",
    "view-events",
    "view-authorization",
    "manage-clients",
    "query-clients",
    "view-realm",
    "manage-events",
    "impersonation",
    "query-realms",
    "manage-authorization",
    "query-groups",
  ]
}

resource "keycloak_group_roles" "infra_keycloak_admin_roles" {
  realm_id = keycloak_realm.infrastructure.id
  group_id = keycloak_group.infra_keycloak_admin.id
  role_ids = [module.realm_admin_role.id]
}
