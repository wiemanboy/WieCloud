variable "name" {
  description = "Name of the client to create in keycloak"
  type        = string
}

variable "namespace" {
  description = "Namespace of where the application is deployed"
  type        = string
}

variable "realm_id" {
  description = "ID of the realm to create the client in"
  type        = string
}

variable "urls" {
  description = "Urls to use for the client, should contain root_url, admin_url, base_url and valid_redirect_uris"
  type = object({
    root                 = string
    admin                = optional(string)
    base                 = optional(string)
    redirect             = list(string)
    post_logout_redirect = optional(list(string))
  })
}
