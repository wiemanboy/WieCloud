variable "name" {
  description = "Name of the port forward"
  type        = string
}

variable "address" {
  description = "Address to route to"
  type        = string
  validation {
    condition     = can(cidrnetmask("${var.address}/32"))
    error_message = "Must be a valid IPv4 address"
  }
}

variable "src_port" {
  description = "The source port"
  type        = string
  validation {
    condition     = can(regex("^[0-9]{1,5}$", var.src_port)) && tonumber(var.src_port) >= 1 && tonumber(var.src_port) <= 65535
    error_message = "Must be a single port number between 1 and 65535"
  }
}

variable "dst_port" {
  description = "The destination port"
  type        = string
  validation {
    condition     = can(regex("^[0-9]{1,5}$", var.dst_port)) && tonumber(var.dst_port) >= 1 && tonumber(var.dst_port) <= 65535
    error_message = "Must be a single port number between 1 and 65535"
  }
}

variable "protocol" {
  description = "The protocol that needs to be used"
  type        = string
  validation {
    condition     = contains(["tcp", "udp"], var.protocol)
    error_message = "Supported protocols are: tcp, udp"
  }
}
