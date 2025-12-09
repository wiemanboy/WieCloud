variable "name" {}
variable "node" {}

variable "iso" {}
variable "macaddr" {}

variable "spec" {
    default = {
        cpu_cores = 4
        disk_size = 100
        memory    = 4096
    }
}
