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

DRY_RUN_TAG=$([[ $DRY_RUN != "false" ]] && echo "--dry-run=client" || echo "")

helm repo add argo https://argoproj.github.io/argo-helm || exit 1

echo "installing argocd helm chart"
helm install argocd argo/argo-cd --version 9.1.3 -n argocd --create-namespace -f infrastructure/argocd/chart/values.yaml $DRY_RUN_TAG || exit 1


echo "creating root application"
kubectl apply -f wiecloud/chart/templates/wiecloud.project.yaml $DRY_RUN_TAG || exit 1
kubectl apply -f wiecloud.application.yaml $DRY_RUN_TAG || exit 1

if [[ $DRY_RUN != "false" ]]; then
  exit
fi

curl -sL https://github.com/operator-framework/operator-lifecycle-manager/releases/download/v0.38.0/install.sh | bash -s v0.38.0 || exit 1

kubectl apply -f https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources/26.4.7/kubernetes/keycloaks.k8s.keycloak.org-v1.yml
kubectl apply -f https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources/26.4.7/kubernetes/keycloakrealmimports.k8s.keycloak.org-v1.yml

DEFAULT_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

kubectl create namespace gateway || exit 1
kubectl create namespace longhorn-system || exit 1
kubectl create namespace keycloak || exit 1
kubectl create namespace harbor || exit 1

kubectl create secret generic server-auth-secret -n gateway --type=kubernetes.io/basic-auth --from-literal=username=admin --from-literal=password=$DEFAULT_PASSWORD
kubectl create secret generic server-auth-secret -n longhorn-system --type=kubernetes.io/basic-auth --from-literal=username=admin --from-literal=password=$DEFAULT_PASSWORD
kubectl create secret generic keycloak-db-secret -n keycloak --from-literal=username=admin --from-literal=password=$DEFAULT_PASSWORD

HARBOR_SECRET=$(yq '.wiecloud.harbor.oidc.clientSecret.secret' env.yaml --raw-output)
kubectl create secret generic harbor-client-secret -n harbor --from-literal=secret=$HARBOR_SECRET

CLOUDFLARE_API_TOKEN=$(yq '.wiecloud.cloudflare.apiToken' env.yaml --raw-output)
kubectl create secret generic cloudflare-api-token --from-literal=api-token=$CLOUDFLARE_API_TOKEN \--namespace=gateway

echo "default password: $DEFAULT_PASSWORD"

# kubectl get secret keycloak-initial-admin -n keycloak -o jsonpath='{.data.username}' | base64 --decode
# kubectl get secret keycloak-initial-admin -n keycloak -o jsonpath='{.data.password}' | base64 --decode