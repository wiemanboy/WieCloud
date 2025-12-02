DRY_RUN=true

while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run)
      DRY_RUN="$2"
      shift 2
      ;;
    *)
      echo "Unknown parameter: $1"
      exit 1
      ;;
  esac
done

DRY_RUN_TAG=$([[ $DRY_RUN != "false" ]] && echo "--dry-run" || echo "")

helm repo add argo https://argoproj.github.io/argo-helm

echo "installing argocd helm chart"
helm install argocd argo/argo-cd --version 9.1.3 -n argocd --create-namespace -f applications/argocd/values.yaml $DRY_RUN_TAG


echo "creating root application"
kubectl apply -f wiecloud.application.yaml $DRY_RUN_TAG

if [[ $DRY_RUN != "false" ]]; then
  exit
fi

curl -sL https://github.com/operator-framework/operator-lifecycle-manager/releases/download/v0.38.0/install.sh | bash -s v0.38.0

DEFAULT_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

kubectl create secret generic server-auth-secret -n gateway --type=kubernetes.io/basic-auth --from-literal=username=admin --from-literal=password=$DEFAULT_PASSWORD
kubectl create secret generic server-auth-secret -n longhorn-system --type=kubernetes.io/basic-auth --from-literal=username=admin --from-literal=password=$DEFAULT_PASSWORD
kubectl create secret generic keycloak-db-secret -n keycloak --from-literal=username=admin --from-literal=password=$DEFAULT_PASSWORD

HARBOR_SECRET=$(yq '.wiecloud.harbor.oidc.clientSecret.secret' env.yaml)
kubectl create secret generic harbor-client-secret -n harbor --from-literal=secret=$HARBOR_SECRET

CLOUDFLARE_API_TOKEN=$(yq '.wiecloud.cloudflare.apiToken' env.yaml)
kubectl create secret generic cloudflare-api-token --from-literal=api-token=$CLOUDFLARE_API_TOKEN \--namespace=gateway

echo "default password: $DEFAULT_PASSWORD"

echo "keycloak initial admin user:"
kubectl get secret keycloak-initial-admin -o jsonpath='{.data.username}' | base64 --decode
kubectl get secret keycloak-initial-admin -o jsonpath='{.data.password}' | base64 --decode