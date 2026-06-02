# Nodes

## Kubelogin

```sh
kubectl oidc-login setup --oidc-issuer-url=https://keycloak.wieman.cloud/realms/wiecloud --oidc-client-id=kubeapi

username=$(
  kubectl oidc-login get-token --oidc-issuer-url=https://keycloak.wieman.cloud/realms/wiecloud --oidc-client-id=kubeapi \
    | jq -r '.status.token' \
    | cut -d '.' -f2 \
    | tr '_-' '/+' \
    | base64 -d \
    | jq -r '.preferred_username'
)

kubectl config set-credentials "$username" \
  --exec-api-version=client.authentication.k8s.io/v1 \
  --exec-interactive-mode=Never \
  --exec-command=kubectl \
  --exec-arg=oidc-login \
  --exec-arg=get-token \
  --exec-arg="--oidc-issuer-url=https://keycloak.wieman.cloud/realms/wiecloud" \
  --exec-arg="--oidc-client-id=kubeapi"

kubectl config set-cluster homelab \
  --server=https://192.168.178.50:6443

kubectl config set-context $username@homelab \
  --cluster=homelab \
  --user="$username"
```
