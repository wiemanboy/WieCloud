set -e

helm repo add argo https://argoproj.github.io/argo-helm || exit 1

echo "installing argocd helm chart"
helm install argocd argo/argo-cd --version 9.1.3 -n argocd --create-namespace

echo "creating root application"
kubectl apply -f argo/infrastructure.project.yaml

kubectl apply -f argo/wiecloud.application.yaml

kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.1/experimental-install.yaml

kubectl apply -f https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources/26.5.2/kubernetes/keycloaks.k8s.keycloak.org-v1.yml
kubectl apply -f https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources/26.5.2/kubernetes/keycloakrealmimports.k8s.keycloak.org-v1.yml
kubectl -n keycloak apply -f https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources/26.5.2/kubernetes/kubernetes.yml

DEFAULT_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "default password: $DEFAULT_PASSWORD"
