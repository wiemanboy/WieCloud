variable "realm_id" {
  description = "ID of the realm"
  type        = string
}

variable "groups" {
  description = "Ids of the groups to add users to"
  type        = list(string)
}

variable "members" {
  description = "Usernames of the user to assign to groups"
  type        = list(string)
}
