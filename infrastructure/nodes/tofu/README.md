# Provisioning

## Network allocation

- Hypervisor: *.0.0.50 - *.0.0.99
- Nodes: *.0.0.100 - *.0.0.200

## Initial network setup

1. Make sure the relevant bridge ports are not bound in RouterOS `Bridge > Ports`
2. Run the below Tofu commands

```sh
export TF_VAR_proxmox_api_url=null
export TF_VAR_proxmox_user_id=null
export TF_VAR_proxmox_user_secret=null
export TF_VAR_routeros_api_url=http://192.168.88.1
export TF_VAR_routeros_username=admin
export TF_VAR_routeros_password=<password>
export TF_VAR_oidc_issuer_url=null

tofu apply -target='module.wiecloud_vlan'
```

## Hypervisor

### Proxmox

1. Install ProxMox via ISO on the machine
2. Configure the admin email `admin@wieman.cloud`
3. Configure the domain name: <host_name>.wieman.cloud
4. Configure the IPs to use one in the Hypervisor ip allocation
5. Make the dhcp lease static in routeros `IP > DHCP Server > Leases > <lease> > Make Static > edit`
6. Create an API token  `Datacenter > permission > API Tokens > Add` disable privilege separation

## Initial node setup

1. Run the below Tofu commands
2. If this is the bootstrap node:
  a. Run `tofu output -json | jq ".kubeconfig.value" | yq > kubeconfig` to get the kubeconfig
  b. Get and approve the CSR with `kubectl --kubeconfig kubeconfig get csr` `kubectl --kubeconfig kubeconfig certificate approve <csr_name>`
  c. The node will not become ready until Cilium is installed
3. Done

```sh
export TF_VAR_proxmox_api_url=https://10.0.0.50:8006/api2/json
export TF_VAR_proxmox_user_id='root@pam!tofu'
export TF_VAR_proxmox_user_secret=<secret>
export TF_VAR_routeros_api_url=http://10.0.0.1
export TF_VAR_routeros_username=admin
export TF_VAR_routeros_password=<password>
export TF_VAR_oidc_issuer_url=https://wieman.cloud

tofu apply
```
