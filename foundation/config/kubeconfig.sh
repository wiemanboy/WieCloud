cd nodes

tofu output -raw kubeconfig > ../config/kubeconfig

export kubeconfig=~/.kube/config:../config/kubeconfig

kubectl config view --merge --flatten > /tmp/merged
mv /tmp/merged ~/.kube/config
chmod 600 ~/.kube/config
