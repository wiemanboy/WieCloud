package main

import (
	"log"

	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
	"wieman.cloud/forgejorunnercontroller/config"
	"wieman.cloud/forgejorunnercontroller/runner"
	"wieman.cloud/forgejorunnercontroller/secret"
)

func main() {
	appConfig := config.LoadConfig()
	kubeconfig, err := rest.InClusterConfig()

	if err != nil {
		log.Fatal(err)
	}

	client, err := kubernetes.NewForConfig(kubeconfig)
	if err != nil {
		log.Fatal(err)
	}

	log.Println("Acquire secret")
	secret.Acquire(appConfig.RunnerSecretName, appConfig.RunnerNamespace, client)

	log.Println("Create ", appConfig.DesiredRunners, " runners")
	runner.Create(appConfig.DesiredRunners, client)
}
