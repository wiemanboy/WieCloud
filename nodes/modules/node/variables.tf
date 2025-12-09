variable "name" {}
variable "node" {}
variable "endpoint" {}
variable "cluster" {}
variable "role" {}

variable "ip" {
  nullable = true
}
variable "macaddr" {
  nullable = true
}

variable "talos_version" {}
variable "iso" {}
variable "image" {}
variable "spec" {
  default = {
    cpu_cores = 4
    disk_size = 100
    memory    = 4096
  }
}
