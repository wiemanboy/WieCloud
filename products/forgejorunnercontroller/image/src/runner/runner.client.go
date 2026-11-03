package runner

import (
	"k8s.io/client-go/kubernetes"
	"wieman.cloud/forgejorunnercontroller/runner/configmap"
	"wieman.cloud/forgejorunnercontroller/runner/secret"
)

type RunnerClient interface {
	CreateRunners()
	CleanupRunners()
	UpdateChecksums()
}

type KubernetesRunnerClient struct {
	k8s                   *kubernetes.Clientset
	runnerSecretClient    secret.RunnerSecretClient
	runnerConfigmapClient configmap.RunnerConfigMapClient
}

func NewKubernetesRunnerClient(k8s *kubernetes.Clientset, rss secret.RunnerSecretClient, rcm configmap.RunnerConfigMapClient) *KubernetesRunnerClient {
	return &KubernetesRunnerClient{
		k8s:                   k8s,
		runnerSecretClient:    rss,
		runnerConfigmapClient: rcm,
	}
}

func (krs *KubernetesRunnerClient) CreateRunners() {}

func (krs *KubernetesRunnerClient) CleanupRunners() {}

func (krs *KubernetesRunnerClient) UpdateChecksums() {}

func (krs *KubernetesRunnerClient) createJob() {
}

func (krs *KubernetesRunnerClient) createDeployment() {
}
