set -e

realm_name=""
target_dir=./realm.export.temp
namespace=keycloak
keycloak_pod_name=keycloak

while [[ $# -gt 0 ]]; do
  case $1 in
    --realm)
      realm_name="$2"
      shift 2
      ;;
   --target-dir)
      target_dir="$2"
      shift 2
      ;;
   --ns)
      namespace="$2"
      shift 2
      ;;
   --keycloak-pod)
      keycloak_pod_name="$2"
      shift 2
      ;;
    *)
      echo "Unknown parameter: $1"
      exit 1
      ;;
  esac
done

mkdir $target_dir

# Gets full name of keycloak pod
pod_name=`kubectl get pods --no-headers -o custom-columns=":metadata.name" --namespace $namespace | grep $keycloak_pod_name`

# Exports config
kubectl exec -it $pod_name --namespace $namespace -- /bin/bash -c "/opt/keycloak/bin/kc.sh export --realm $realm_name --dir=/opt/keycloak/Backups"

# Cat files to local filesystem
kubectl exec -i $pod_name -n $namespace -- cat /opt/keycloak/Backups/$realm_name-realm.json | yq -P > $target_dir/$realm_name-realm.yaml

# Depending on how many users there are, keycloak will create multiple export jsons for them
FILE_COUNT=$(kubectl exec -i $pod_name -n $namespace -- ls -l /opt/keycloak/Backups/ | grep ${realm_name} | wc -l)
for ((i=0; i<$FILE_COUNT-1; i++))
do 
   kubectl exec -i $pod_name -n $namespace -- cat /opt/keycloak/Backups/$realm_name-users-$i.json | yq -P  > $target_dir/$realm_name-users-$i.yaml
done
