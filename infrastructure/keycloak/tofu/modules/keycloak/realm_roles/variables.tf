variable "name" {
  description = "Name of the realm role"
  type        = string
}

variable "description" {
  description = "Description for the realm role"
  type        = string
}

variable "realm_id" {
  description = "ID of the realm"
  type        = string
}

variable "realm_permissions" {
  description = "Permissions to give to the realm_role"
  type        = list(string)
}
