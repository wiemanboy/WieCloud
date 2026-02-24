variable "name" {
  description = "Name of the config secret"
  type        = string
}

variable "namespace" {
  description = "Namespace of the config secret"
  type        = string
}

variable "identities" {
  description = "Identities to create and where to use them"
  type = list(object({
    name       = string
    namespaces = optional(list(string))
    type       = string
    credentials = optional(list(object({
      accessKey = string
      secretKey = string
    })))
  }))
}
