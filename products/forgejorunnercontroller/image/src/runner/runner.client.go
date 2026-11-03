package runner

import (
	"context"
	"log"
	"log/slog"
	"time"

	appsv1 "k8s.io/api/apps/v1"
	apierrors "k8s.io/apimachinery/pkg/api/errors"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/util/wait"
	"k8s.io/client-go/kubernetes"
	"sigs.k8s.io/yaml"
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

func (rc *KubernetesRunnerClient) CleanupRunners(desiredAmount int, runner Runner) error {
	deployments, err := rc.getDeployments(runner.Namespace, runner.Label)
	runnerCount, err := rc.runnerSecretClient.CountSecrets(runner.Namespace, runner.Label)
	log.Println("Counted", runnerCount, "runners")

	if err != nil {
		return err
	}

	for _, deployment := range deployments {
		if len(deployments) > desiredAmount {
			slog.Info("Deleting secret for runner " + deployment.OwnerReferences[0].Name)
			err := rc.k8s.CoreV1().Secrets(deployment.Namespace).Delete(context.Background(), deployment.OwnerReferences[0].Name, metav1.DeleteOptions{})

			err = wait.PollUntilContextTimeout(
				context.Background(),
				500*time.Millisecond,
				30*time.Second,
				true,
				func(ctx context.Context) (bool, error) {
					_, err := rc.k8s.CoreV1().
						Secrets(deployment.Namespace).
						Get(ctx, deployment.OwnerReferences[0].Name, metav1.GetOptions{})

					if apierrors.IsNotFound(err) {
						return true, nil
					}
					if err != nil {
						return false, err
					}

					return false, nil
				},
			)

			if err != nil {
				log.Println("Failed to delete runner " + deployment.Name)
				log.Println(err)
				return err
			}

			rc.CleanupRunners(desiredAmount, runner)
		}
	}

	return nil
}

func (rc *KubernetesRunnerClient) UpdateChecksums(runner Runner) error {
	deployments, err := rc.getDeployments(runner.Namespace, runner.Label)

	if err != nil {
		return err
	}

	for _, deployment := range deployments {
		deployment.Spec.Template.Annotations["wieman.cloud/runner-config-checksum"] = runner.ConfigChecksum
		_, err := rc.k8s.AppsV1().Deployments(runner.Namespace).Update(context.Background(), &deployment, metav1.UpdateOptions{})

		if err != nil {
			slog.Error("Failed to update deployment", "error", err)
			return err
		}
	}

	return nil
}

func (rc *KubernetesRunnerClient) createJob(secretRefs secret.SecretsRefs, register Register, runner Runner) {
	slog.Info("Creating job for runner", "runner", runner.Label)

	runnerDeployment := deployment(secretRefs, runner)

	deploymentBytes, _ := yaml.Marshal(runnerDeployment)
	deploymentYaml := string(deploymentBytes)

	_, err := rc.k8s.BatchV1().Jobs(register.Namespace).Create(
		context.Background(),
		job(
			secretRefs,
			register,
			runner,
			deploymentYaml,
		),
		metav1.CreateOptions{})

	if err != nil {
		slog.Error("Error creating job", "error", err)
	}
}

func (rc *KubernetesRunnerClient) getDeployments(namespace string, label string) ([]appsv1.Deployment, error) {
	deployments, err := rc.k8s.AppsV1().Deployments(namespace).List(context.Background(), metav1.ListOptions{LabelSelector: label})

	if err != nil {
		slog.Error("Failed to list deployments", "error", err)
		return []appsv1.Deployment{}, err
	}

	return deployments.Items, nil
}

func (rc *KubernetesRunnerClient) createDeployment() {
}
