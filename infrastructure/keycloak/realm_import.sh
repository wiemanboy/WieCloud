set -e

realm_name=master
target_dir=./master-realm.temp
namespace=keycloak
secret_name=keycloak-${realm_name}-realm

mkdir -p "$target_dir"

kubectl get secret "$secret_name" -n "$namespace" -o jsonpath='{.data.master-realm\.json}' | base64 -d > "$target_dir/$realm_name-realm.import.json"
