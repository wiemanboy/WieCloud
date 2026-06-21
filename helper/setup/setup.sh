set -e

cilium_version=1.19.5
argocd_version=9.5.15

# Setup Cilium

helm repo add cilium https://helm.cilium.io/ || exit 1
helm repo update

helm install cilium cilium/cilium --version ${cilium_version} --namespace kube-system --values ./cilium/values.yaml

# Setup ArgoCD

helm repo add argo https://argoproj.github.io/argo-helm || exit 1
helm repo update

echo "installing argocd helm chart"
helm install argocd argo/argo-cd --version ${argocd_version} -n argocd --create-namespace

echo "creating root application"
kubectl apply -f argo/infrastructure.project.yaml

kubectl apply -f argo/wiecloud.application.yaml

kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.1/experimental-install.yaml

DEFAULT_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "default password: $DEFAULT_PASSWORD"
