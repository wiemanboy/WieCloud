variable "endpoint" {} // 192.168.178.47
variable "cluster" {}
variable "node" {}

variable "image" {}
variable "talos_version" {
  default = "v1.11.5"
}
variable "role" {
  default = "worker"
}
