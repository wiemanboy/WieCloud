package configmap

import (
	"context"
	"crypto/sha256"
	"fmt"
	"log"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
)

func GetChecksum(configName string, namespace string, client *kubernetes.Clientset) (string, error) {
	configMap, err := client.CoreV1().ConfigMaps(namespace).Get(context.Background(), configName, metav1.GetOptions{})
	if err != nil {
		log.Println("Failed to get config")
		log.Println(err)
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
