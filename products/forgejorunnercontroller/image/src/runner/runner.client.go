package runner

import (
	"log"

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

func (rc *KubernetesRunnerClient) CreateRunners(amount int, secretName string, register Register, runner Runner) error {
	runnerCount, _ := rc.runnerSecretClient.CountSecrets(runner.Label, runner.Namespace)
	log.Println("Counted", runnerCount, "runners")

	if runnerCount < amount {
		secretRefs, _ := rc.runnerSecretClient.CreateSecrets(
			secret.Secret{
				Name:              secretName,
				Label:             runner.Label,
				RegisterNamespace: register.Namespace,
				RunnerNamespace:   runner.Namespace,
			},
		)

		rc.createJob(secretRefs, register, runner)
		rc.CreateRunners(amount, secretName, register, runner)
	}

	log.Println("All runners created")
	return nil
}

func (krs *KubernetesRunnerClient) CleanupRunners() {}

func (krs *KubernetesRunnerClient) UpdateChecksums() {}

func (krs *KubernetesRunnerClient) createJob(secretRefs secret.SecretsRefs, register Register, runner Runner) {
}

func (krs *KubernetesRunnerClient) createDeployment() {
}
