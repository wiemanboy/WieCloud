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
