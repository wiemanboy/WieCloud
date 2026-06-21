variable "name" {
  description = "Name of the talos node"
  type        = string
}

variable "region" {
  description = "Name of the region the node is located in"
  type        = string
}

variable "zone" {
  description = "Name of the zone the node is located in"
  type        = string
}

variable "endpoint" {
  description = "Endpoint of the controlplane"
  type        = string
}

variable "cluster" {
  description = "Name of the cluster"
  type        = string
}

variable "node" {
  description = "Ip of the node"
  type        = string
}

variable "image" {}
variable "talos_version" {
  description = "Talos version to use"
  type        = string
}


variable "machine_secret" {
  description = "Talos machine secrets"
}

variable "role" {
  description = "Role of the node, can be `controlplane` or `worker`"
  type        = string
  validation {
    condition     = contains(["worker", "controlplane"], var.role)
    error_message = "Role must be either 'worker' or 'controlplane'."
  }
}

variable "bootstrap" {
  description = "If the machine should be bootstrapped, only needed on one controlplane"
  type        = bool
  default     = false
}

variable "oidc" {
  description = "OIDC configuration"
  type = object({
    issuer_url = string
  })
  nullable = true
  default  = null
}

variable "extra_config" {
  description = "Extra talos configuration passed to the machine"
  type        = object(any)
  default     = {}
}
