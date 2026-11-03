package configmap

import (
	"context"
	"crypto/sha256"
	"fmt"
	"log/slog"

	"k8s.io/client-go/kubernetes"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

type RunnerConfigMapClient interface {
	GetChecksum(configName string, namespace string) (string, error)
}

type KubernetesRunnerConfigMapClient struct {
	k8s *kubernetes.Clientset
}

func NewKubernetesConfigMapClient(k8s *kubernetes.Clientset) *KubernetesRunnerConfigMapClient {
	return &KubernetesRunnerConfigMapClient{
		k8s: k8s,
	}
}

func (kcs *KubernetesRunnerConfigMapClient) GetChecksum(configName string, namespace string) (string, error) {
	configMap, err := kcs.k8s.CoreV1().ConfigMaps(namespace).Get(context.Background(), configName, metav1.GetOptions{})
	if err != nil {
		slog.Error("Failed to get config", "configName", configName, "namespace", namespace, "error", err)
		return "", err
	}

	hash := sha256.New()

	// Hash all key-value pairs in consistent order
	for key, value := range configMap.Data {
		hash.Write([]byte(key))
		hash.Write([]byte(value))
	}

	checksum := fmt.Sprintf("%x", hash.Sum(nil))
	return checksum, nil
}
