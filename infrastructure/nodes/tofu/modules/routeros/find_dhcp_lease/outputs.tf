output "data" {
  description = <<EOT
  {
    active_address (String)
    active_client_id (String)
    active_mac_address (String)
    active_server (String)
    address (String)
    address_lists (String)
    age (String)
    allow_dual_stack_queue (Boolean)
    blocked (Boolean)
    class_id (String)
    client_id (String)
    comment (String)
    dhcp_option (String)
    disabled (Boolean)
    dynamic (Boolean)
    expires_after (String)
    host_name (String)
    id (String)
    last_seen (String)
    mac_address (String)
    radius (Boolean)
    server (String)
    status (String)hello
    world
  }
  EOT
  value = [for lease in data.routeros_ip_dhcp_server_leases.leases.data : lease if lease.host_name == var.hostname]
}
