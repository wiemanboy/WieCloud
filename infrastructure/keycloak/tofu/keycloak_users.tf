resource "random_password" "jarno_wieman_password" {
  length = 20
}

resource "keycloak_user" "jarno_wieman" {
  realm_id       = keycloak_realm.wiecloud.id
  username       = "jarno_wieman"
  first_name     = "Jarno"
  last_name      = "Wieman"
  email          = "wiemanboy@gmail.com"
  email_verified = true
  enabled        = true

  initial_password {
    value     = random_password.jarno_wieman_password.result
    temporary = true
  }

  required_actions = [
    "UPDATE_PASSWORD",
    "CONFIGURE_TOTP",
  ]

  lifecycle {
    ignore_changes = [
      required_actions
    ]
  }
}

module "admin_memberships" {
  source = "./modules/keycloak/groups_memberships"

  realm_id = keycloak_realm.wiecloud.id
  groups = [
    module.app_group.child_groups.admin.id,
    module.app_nextcloud_group.child_groups.admin.id,

    module.infra_group.child_groups.admin.id,
    module.infra_argocd_group.child_groups.admin.id,
    module.infra_grafana_group.child_groups.admin.id,
    module.infra_harbor_group.child_groups.admin.id,
    module.infra_keycloak_group.child_groups.admin.id,
    module.infra_longhorn_group.child_groups.admin.id,
    module.infra_kubernetes_group.child_groups.admin.id,
  ]

  members = [keycloak_user.jarno_wieman.username]
}
