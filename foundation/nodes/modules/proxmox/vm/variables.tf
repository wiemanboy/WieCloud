variable "name" {
  description = "Name of the vm created"
  type        = string
}

variable "node" {
  description = "Name of the node to create the vm on"
  type        = string
}

variable "iso" {
  description = "ISO to create the vm with, format: <storage>:iso/<filename>"
  type        = string
}

variable "macaddr" {
  description = "Mac address of the vm"
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