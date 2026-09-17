variable "realm_id" {
  description = "ID of the realm"
  type        = string
}

variable "group_memberships" {
  description = "List of group/member sets, each assigning a list of members to a list of groups"
  type = list(object({
    name    = string
    groups  = list(string)
    members = list(string)
  }))
}
