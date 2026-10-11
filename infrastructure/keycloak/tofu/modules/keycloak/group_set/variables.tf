variable "name" {
  description = "Name of the parent group"
  type        = string
}

variable "realm_id" {
  description = "ID of the realm"
  type        = string
}

variable "parent_id" {
  description = "ID of the parent group"
  type        = string
  default     = null
}
