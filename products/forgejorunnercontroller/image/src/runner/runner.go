package runner

import (
	"log"

	"k8s.io/client-go/kubernetes"
)

func Create(amount int, client *kubernetes.Clientset) error {
	log.Println("Creating runners")
	count(client)
	createJob(client)
	return nil
}

func count(client *kubernetes.Clientset) int {
	log.Println("Counting runners")
	return 0
}

func createJob(client *kubernetes.Clientset) {
	log.Println("Creating job")
}
