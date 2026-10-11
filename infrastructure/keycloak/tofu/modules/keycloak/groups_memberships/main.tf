resource "keycloak_user_groups" "group_membership" {
  for_each = toset(var.members)

  user_id    = each.value
  realm_id   = var.realm_id
  group_ids  = var.groups
  exhaustive = false
}
