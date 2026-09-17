resource "keycloak_group_memberships" "group_membership" {
  for_each = toset(var.groups)

  realm_id = var.realm_id
  group_id = each.value
  members  = var.members
}
