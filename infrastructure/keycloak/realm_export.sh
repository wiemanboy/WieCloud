REALM_NAME=""
TARGET_DIR=./realm.export.temp
NAMESPACE=keycloak
KEYCLOAK_POD_NAME_KEYWORD=keycloak

while [[ $# -gt 0 ]]; do
  case $1 in
    --realm)
      REALM_NAME="$2"
      shift 2
      ;;
   --target-dir)
      TARGET_DIR="$2"
      shift 2
      ;;
   --ns)
      NAMESPACE="$2"
      shift 2
      ;;
   --keycloak-pod)
      KEYCLOAK_POD_NAME_KEYWORD="$2"
      shift 2
      ;;
    *)
      echo "Unknown parameter: $1"
      exit 1
      ;;
  esac
done

mkdir $TARGET_DIR

# Gets full name of keycloak pod
POD_NAME=`kubectl get pods --no-headers -o custom-columns=":metadata.name" --namespace $NAMESPACE | grep $KEYCLOAK_POD_NAME_KEYWORD`

# Exports config
kubectl exec -it $POD_NAME --namespace $NAMESPACE -- /bin/bash -c "/opt/keycloak/bin/kc.sh export --realm $REALM_NAME --dir=/opt/keycloak/Backups"

# Cat files to local filesystem
kubectl exec -i $POD_NAME -n $NAMESPACE -- cat /opt/keycloak/Backups/$REALM_NAME-realm.json | yq -P > $TARGET_DIR/$REALM_NAME-realm.yaml

# Depending on how many users there are, keycloak will create multiple export jsons for them
FILE_COUNT=$(kubectl exec -i $POD_NAME -n $NAMESPACE -- ls -l /opt/keycloak/Backups/ | grep ${REALM_NAME} | wc -l)
for ((i=0; i<$FILE_COUNT-1; i++))
do 
   kubectl exec -i $POD_NAME -n $NAMESPACE -- cat /opt/keycloak/Backups/$REALM_NAME-users-$i.json | yq -P  > $TARGET_DIR/$REALM_NAME-users-$i.yaml
done