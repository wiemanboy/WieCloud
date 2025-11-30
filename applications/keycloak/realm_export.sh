REALM_NAME=master
TARGET_DIR=./master-realm.temp
NAMESPACE=keycloak
KEYCLOAK_POD_NAME_KEYWORD=keycloak

# Gets full name of keycloak pod
POD_NAME=`kubectl get pods --no-headers -o custom-columns=":metadata.name" --namespace $NAMESPACE | grep $KEYCLOAK_POD_NAME_KEYWORD`

# Exports config
kubectl exec -it $POD_NAME --namespace $NAMESPACE -- /bin/bash -c "/opt/keycloak/bin/kc.sh export --realm $REALM_NAME --dir=/opt/keycloak/Backups"

# Cat files to local filesystem
kubectl exec -i $POD_NAME -n $NAMESPACE -- cat /opt/keycloak/Backups/$REALM_NAME-realm.json > $TARGET_DIR/$REALM_NAME-realm.json

# Depending on how many users there are, keycloak will create multiple export jsons for them
FILE_COUNT=$(kubectl exec -i $POD_NAME -n $NAMESPACE -- ls -l /opt/keycloak/Backups/ | grep ${REALM_NAME} | wc -l)
for ((i=0; i<$FILE_COUNT-1; i++))
do 
   kubectl exec -i $POD_NAME -n $NAMESPACE -- cat /opt/keycloak/Backups/$REALM_NAME-users-$i.json > $TARGET_DIR/$REALM_NAME-users-$i.json
done