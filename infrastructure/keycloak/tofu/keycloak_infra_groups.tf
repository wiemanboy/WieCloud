module "infra_group" {
  source   = "./modules/keycloak/user_group"
  realm_id = keycloak_realm.wiecloud.id
  name     = "infra"
}

module "infra_argocd_group" {
  source    = "./modules/keycloak/user_group"
  realm_id  = keycloak_realm.wiecloud.id
  parent_id = module.infra_group.id
  name      = "argocd"
}

module "infra_grafana_group" {
  source    = "./modules/keycloak/user_group"
  realm_id  = keycloak_realm.wiecloud.id
  parent_id = module.infra_group.id
  name      = "grafana"
}

module "infra_harbor_group" {
  source    = "./modules/keycloak/user_group"
  realm_id  = keycloak_realm.wiecloud.id
  parent_id = module.infra_group.id
  name      = "harbor"
}

module "infra_keycloak_group" {
  source    = "./modules/keycloak/user_group"
  realm_id  = keycloak_realm.wiecloud.id
  parent_id = module.infra_group.id
  name      = "keycloak"
}

module "realm_admin_role" {
  source   = "./modules/keycloak/realm_roles"
  realm_id = keycloak_realm.wiecloud.id

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

module "infra_kubernetes_group" {
  source    = "./modules/keycloak/user_group"
  realm_id  = keycloak_realm.wiecloud.id
  parent_id = module.infra_group.id
  name      = "kubernetes"
}

resource "keycloak_group_roles" "infra_keycloak_admin_roles" {
  realm_id = keycloak_realm.wiecloud.id
  group_id = module.infra_keycloak_group.child_groups.admin.id
  role_ids = [module.realm_admin_role.id]
}
