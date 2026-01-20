set -e

REALM_NAME=master
TARGET_DIR=./master-realm.temp
NAMESPACE=keycloak
SECRET_NAME=keycloak-${REALM_NAME}-realm

mkdir -p "$TARGET_DIR"

kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" -o jsonpath='{.data.master-realm\.json}' | base64 -d > "$TARGET_DIR/$REALM_NAME-realm.import.json"
