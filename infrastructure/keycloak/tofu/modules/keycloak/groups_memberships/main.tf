locals {
  # Convert each membership entry into a list of {group, members} objects
  group_member_pairs = flatten([
    for membership in var.group_memberships : [
      for group in membership.groups : {
        group   = group
        members = membership.members
      }
    ]
  ])

  # Create a map: group_name => members
  group_memberships_by_group = {
    for pair in local.group_member_pairs :
    pair.group => pair.members
  }
}


resource "keycloak_group_memberships" "group_membership" {
  for_each = local.group_memberships_by_group

  realm_id = var.realm_id
  group_id = each.key
  members  = each.value
}
