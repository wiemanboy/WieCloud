package secret

import (
	"context"
	"crypto/rand"
	"errors"
	"log"

	corev1 "k8s.io/api/core/v1"
	apierrors "k8s.io/apimachinery/pkg/api/errors"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
)

func Acquire(name string, namespace string, client *kubernetes.Clientset) (string, error) {
	secret, err := get(name, namespace, client)

	if secret != "" {
		return secret, nil
	}

	if !apierrors.IsNotFound(err) {
		return "", err
	}

	return create(name, namespace, client)
}

func get(name string, namespace string, client *kubernetes.Clientset) (string, error) {
	k8sSecret, err := client.CoreV1().Secrets(namespace).Get(context.Background(), name, metav1.GetOptions{})

	if err != nil {
		log.Println("K8s Secret ", name, " in namespace ", namespace, " does not exist")
		return "", err
	}

	secretBytes, ok := k8sSecret.Data["secret"]

	if !ok {
		log.Println("Key \"secret\" does not exist")
		return "", errors.New("Key \"secret\"  does not exist")
	}

	return string(secretBytes), nil
}

func create(name string, namespace string, client *kubernetes.Clientset) (string, error) {

	secret := rand.Text()

	k8sSecret := &corev1.Secret{
		Type: corev1.SecretTypeOpaque,
		ObjectMeta: metav1.ObjectMeta{
			Name:      name,
			Namespace: namespace,
		},
		StringData: map[string]string{
			"secret": secret,
		},
	}

	_, err := client.CoreV1().Secrets(namespace).Create(context.Background(), k8sSecret, metav1.CreateOptions{})

	if err != nil {
		log.Println("Failed creating new secret")
		return "", err
	}

	return secret, nil
}
