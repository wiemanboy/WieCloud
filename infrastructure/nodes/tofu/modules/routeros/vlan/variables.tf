variable "vlan_name" {
  description = "Name of the VLAN"
  type        = string
}

variable "vlan_id" {
  description = "ID of the VLAN"
  type        = number
}

variable "subnet" {
  description = "Subnet to use for the VLAN: 10.0.0.1/24"
  type        = string
}

variable "ip_range" {
  description = "IP range to use for dhcp: 10.0.0.100-10.0.0.200"
  type        = string
}

variable "gateway_ports" {
  description = "Ethernet ports to use as a gateway to the VLAN"
  type        = list(string)
}

variable "vpn" {
  description = "VPN configuration"
  type = object({
    endpoint = string
    address  = string
    port     = number
    users = list(object({
      name = string
      peers = list(object({
        id   = number
        name = string
      }))
    }))
  })
}
