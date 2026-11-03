package secret

import (
	"context"
	"log"
	"log/slog"
	"strings"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/types"
	"k8s.io/client-go/kubernetes"
	"wieman.cloud/forgejorunnercontroller/utils/k8s"
	"wieman.cloud/forgejorunnercontroller/utils/rand"
)

type RunnerSecretClient interface {
	CreateSecrets(secret Secret) (SecretsRefs, error)
	CountSecrets(label string, namespace string) (int, error)
}

type KubernetesRunnerSecretClient struct {
	k8s *kubernetes.Clientset
}

func NewKubernetesRunnerSecretClient(client *kubernetes.Clientset) *KubernetesRunnerSecretClient {
	return &KubernetesRunnerSecretClient{
		k8s: client,
	}
}

type Secret struct {
	Name              string
	Label             string
	RegisterNamespace string
	RunnerNamespace   string
}

type SecretRef struct {
	Name       string
	Namespace  string
	UID        types.UID
	ApiVersion string
	Kind       string
}

type SecretsRefs struct {
	RegisterSecret SecretRef
	RunnerSecret   SecretRef
}

func (rsc *KubernetesRunnerSecretClient) CreateSecrets(secret Secret) (SecretsRefs, error) {
	sharedSecret := rand.HexString(40)
	namePostfix := strings.ToLower(rand.String(5))

	forgejoSecretBuilder := k8s.NewRunnerSecretBuilder()
	forgejoSecretBuilder.
		SetName(secret.Name).
		SetPostfix(namePostfix).
		SetNamespace(secret.RegisterNamespace).
		SetLabel(secret.Label).
		SetValue(sharedSecret)

	forgejoSecret, err := rsc.k8s.CoreV1().Secrets(secret.RegisterNamespace).Create(context.Background(), forgejoSecretBuilder.Build(), metav1.CreateOptions{})
	runnerSecret, err := rsc.k8s.CoreV1().Secrets(secret.RunnerNamespace).Create(context.Background(), forgejoSecretBuilder.Build(), metav1.CreateOptions{})

	if err != nil {
		log.Println("Failed creating secrets")
		log.Println(err)
		return SecretsRefs{}, nil
	}

	return SecretsRefs{
		RegisterSecret: SecretRef{
			Name:       forgejoSecret.Name,
			Namespace:  forgejoSecret.Namespace,
			UID:        forgejoSecret.UID,
			ApiVersion: forgejoSecret.APIVersion,
			Kind:       forgejoSecret.Kind,
		},
		RunnerSecret: SecretRef{
			Name:       runnerSecret.Name,
			Namespace:  runnerSecret.Namespace,
			UID:        runnerSecret.UID,
			ApiVersion: runnerSecret.APIVersion,
			Kind:       runnerSecret.Kind,
		},
	}, nil
}

func (rsc *KubernetesRunnerSecretClient) CountSecrets(label string, namespace string) (int, error) {
	slog.Info("Counting secrets with label " + label + " in namespace " + namespace)

	secrets, err := rsc.k8s.CoreV1().Secrets(namespace).List(context.Background(), metav1.ListOptions{LabelSelector: label})

	if err != nil {
		slog.Error("Failed to list secrets", "error", err)
		return 99999, err
	}

	return len(secrets.Items), nil
}
