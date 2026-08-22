package secret

import (
	"context"
	"log"
	"strings"

	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"wieman.cloud/forgejorunnercontroller/utils/rand"
)

type Secret struct {
	Name             string
	Label            string
	ForgejoNamespace string
	RunnerNamespace  string
}

type secretRef struct {
	name      string
	namespace string
	uid       string
}

type secretsRefs struct {
	ForgejoSecret secretRef
	RunnerSecret  secretRef
}

func Create(secret Secret, namespaces []string, client *kubernetes.Clientset) (secretsRefs, error) {
	sharedSecret := rand.HexString(40)
	namePostfix := strings.ToLower(rand.String(5))

	forgejoSecret, err := createSecret(sharedSecret, secret.ForgejoNamespace, namePostfix, secret, client)
	runnerSecret, err := createSecret(sharedSecret, secret.RunnerNamespace, namePostfix, secret, client)

	if err != nil {
		log.Println("Failed creating secrets")
		log.Println(err)
		return secretsRefs{}, nil
	}

	return secretsRefs{
		ForgejoSecret: forgejoSecret,
		RunnerSecret:  runnerSecret,
	}, nil
}

func createSecret(value string, namespace string, namePostfix string, secret Secret, client *kubernetes.Clientset) (secretRef, error) {
	k8sSecret := &corev1.Secret{
		Type: corev1.SecretTypeOpaque,
		ObjectMeta: metav1.ObjectMeta{
			Name:      secret.Name + "-" + namePostfix,
			Namespace: namespace,
			Labels:    map[string]string{secret.Label: ""},
			Annotations:  map[string]string{"argocd.argoproj.io/tracking-id": "forgejo:apps/Deployment:forgejo/forgejo-runner-controller"},
		},
		StringData: map[string]string{
			"secret": value,
		},
	}

	createdSecret, err := client.CoreV1().Secrets(namespace).Create(context.Background(), k8sSecret, metav1.CreateOptions{})

	if err != nil {
		log.Println("Failed creating secret")
		log.Println(err)
		return secretRef{}, err
	}

	return secretRef{
		name:      createdSecret.Name,
		namespace: createdSecret.Namespace,
		uid:       string(createdSecret.GetUID()),
	}, nil
}
