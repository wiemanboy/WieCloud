# Provisioning

## Initial network setup

```sh
export TF_VAR_proxmox_api_url=null
export TF_VAR_proxmox_user_id=null
export TF_VAR_proxmox_user_secret=null
export TF_VAR_routeros_api_url=http://192.168.88.1
export TF_VAR_routeros_username=admin
export TF_VAR_routeros_password=iAnqYuhgR5oshRZPhaNO
export TF_VAR_oidc_issuer_url=null

tofu apply -target='module.wiecloud_vlan'
```

## Initial node setup

```sh
export TF_VAR_proxmox_api_url=https://10.0.0.101:8006/api2/json
# export TF_VAR_proxmox_user_id="root@pam!tofu"
export TF_VAR_proxmox_user_secret="a1587b17-27d6-4b11-9af0-6e4f39ab0a1e"
export TF_VAR_routeros_api_url=http://10.0.0.1
export TF_VAR_routeros_username=admin
export TF_VAR_routeros_password=iAnqYuhgR5oshRZPhaNO
export TF_VAR_oidc_issuer_url=null

tofu apply
```
