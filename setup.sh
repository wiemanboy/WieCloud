helm repo add argo https://argoproj.github.io/argo-helm

helm install argocd argo/argo-cd --version 9.1.3 -n argocd --create-namespace -f applications/argocd/values.yaml


echo "creating root application"
kubectl apply -f wiecloud.application.yaml


echo "TODO: remove this later"
echo "default argo password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)"
echo "setup cloudflare api token secret:"
echo "kubectl create secret generic cloudflare-api-token --from-literal=api-token=<CLOUDFLARE_API_TOKEN> \--namespace=gateway"