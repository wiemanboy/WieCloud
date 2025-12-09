variable "endpoint" {}
variable "cluster" {}
variable "node" {}

variable "image" {}
variable "talos_version" {
  default = "v1.11.5"
}
variable "role" {
  type = string
  validation {
    condition     = contains(["worker", "controlplane"], var.role)
    error_message = "Role must be either 'worker' or 'controlplane'."
  }
  default = "worker"
}
