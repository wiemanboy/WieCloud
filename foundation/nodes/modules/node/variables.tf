variable "name" {
  description = "Name of the vm created"
  type        = string
}

variable "node" {
  description = "Name of the node to create the vm on"
  type        = string
}

variable "endpoint" {
  description = "Ip of the controlplane"
  type        = string
}

variable "cluster" {
  description = "Name of the cluster"
  type        = string
}

variable "role" {
  description = "Role of the node, can be `controlplane` or `worker`"
  type        = string
  validation {
    condition     = contains(["worker", "controlplane"], var.role)
    error_message = "Role must be either 'worker' or 'controlplane'."
  }
}

variable "ip" {
  description = "Ip of the vm"
  type        = string
}
variable "macaddr" {
  description = "Mac address of the vm"
  type        = string
}

variable "machine_secret" {
  description = "Talos machine secrets"
}

variable "talos_version" {
  description = "Talos version to use"
  type        = string
}

variable "iso" {
  description = "ISO to create the vm with, format: <storage>:iso/<filename>"
  type        = string
}

variable "image" {
  description = "Talos image to use"
  type        = string
}

variable "spec" {
  description = "Resources assigned to the vm"
  type = object({
    cpu_cores = number
    disk_size = number
    memory    = number
  })
  default = {
    cpu_cores = 4
    disk_size = 100
    memory    = 4096
  }
}

variable "bootstrap" {
  description = "If the machine should be bootstrapped, only needed on one controlplane"
  type = bool
  default = false
}
