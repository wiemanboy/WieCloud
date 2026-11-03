package configmap

import "k8s.io/client-go/kubernetes"

type RunnerConfigMapClient interface {
	GetChecksum()
}

type KubernetesRunnerConfigMapClient struct {
	client *kubernetes.Clientset
}

func NewKubernetesConfigMapClient(client *kubernetes.Clientset) *KubernetesRunnerConfigMapClient {
	return &KubernetesRunnerConfigMapClient{
		client: client,
	}
}

func (kcs *KubernetesRunnerConfigMapClient) GetChecksum() {}
