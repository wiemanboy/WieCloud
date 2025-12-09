terraform output -raw kubeconfig > kubeconfig

export KUBECONFIG=~/.kube/config:kubeconfig
kubectl config view --merge --flatten > /tmp/merged
mv /tmp/merged ~/.kube/config
chmod 600 ~/.kube/config
