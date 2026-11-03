package secret

import "k8s.io/client-go/kubernetes"

type RunnerSecretClient interface {
	CreateSecrets()
}

type KubernetesRunnerSecretClient struct {
	k8s *kubernetes.Clientset
}

func NewKubernetesRunnerSecretClient(client *kubernetes.Clientset) *KubernetesRunnerSecretClient {
	return &KubernetesRunnerSecretClient{
		k8s: client,
	}
}

func (s *KubernetesRunnerSecretClient) CreateSecrets() {}
