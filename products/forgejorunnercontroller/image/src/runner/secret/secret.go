package secret

import (
	"context"
	"log"
	"strings"

	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/types"
	"k8s.io/client-go/kubernetes"
	"wieman.cloud/forgejorunnercontroller/utils/rand"
)

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

func Create(secret Secret, client *kubernetes.Clientset) (SecretsRefs, error) {
	sharedSecret := rand.HexString(40)
	namePostfix := strings.ToLower(rand.String(5))

	forgejoSecret, err := createSecret(sharedSecret, secret.RegisterNamespace, namePostfix, secret, client)
	runnerSecret, err := createSecret(sharedSecret, secret.RunnerNamespace, namePostfix, secret, client)

	if err != nil {
		log.Println("Failed creating secrets")
		log.Println(err)
		return SecretsRefs{}, nil
	}

	return SecretsRefs{
		RegisterSecret: forgejoSecret,
		RunnerSecret:   runnerSecret,
	}, nil
}

func Count(namespace string, label string, client *kubernetes.Clientset) (int, error) {
	log.Println("Counting secrets with label " + label + " in namespace " + namespace)

	secrets, err := client.CoreV1().Secrets(namespace).List(context.Background(), metav1.ListOptions{LabelSelector: label})

	if err != nil {
		log.Println("Failed to list secrets")
		log.Println(err)
		return 99999, err
	}

	return len(secrets.Items), nil
}

func createSecret(value string, namespace string, namePostfix string, secret Secret, client *kubernetes.Clientset) (SecretRef, error) {
	k8sSecret := &corev1.Secret{
		Type: corev1.SecretTypeOpaque,
		ObjectMeta: metav1.ObjectMeta{
			Name:        secret.Name + "-" + namePostfix,
			Namespace:   namespace,
			Labels:      map[string]string{secret.Label: ""},
			Annotations: map[string]string{"argocd.argoproj.io/tracking-id": "forgejo:apps/Deployment:forgejo/forgejo-runner-controller"},
		},
		StringData: map[string]string{
			"secret": value,
		},
	}

	createdSecret, err := client.CoreV1().Secrets(namespace).Create(context.Background(), k8sSecret, metav1.CreateOptions{})

	if err != nil {
		log.Println("Failed creating secret")
		log.Println(err)
		return SecretRef{}, err
	}

	return SecretRef{
		Name:       createdSecret.Name,
		Namespace:  createdSecret.Namespace,
		UID:        createdSecret.GetUID(),
		ApiVersion: "v1",
		Kind:       "Secret",
	}, nil
}
