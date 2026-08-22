package main

import (
	"log"
	"time"

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

	for {
		log.Println("Acquire secret")
		secret, _ := secret.Acquire(appConfig.RunnerSecretName, appConfig.RunnerNamespace, client)

		log.Println("Create ", appConfig.DesiredRunners, " runners")
		runner.Create(
			appConfig.DesiredRunners,
			secret,
			runner.Register{
				Namespace:    appConfig.ForgejoNamespace,
				ForgejoImage: appConfig.ForgejoImage,
				KubectlImage: appConfig.KubectlImage,
			},
			runner.Runner{
				Name:      "wiecloud-runner",
				Label:     "wieman.cloud/wiecloud-runner",
				Instance:  "https://forgejo.wieman.cloud",
				Namespace: appConfig.RunnerNamespace,
				Image:     appConfig.RunnerImage,
				DindImage: appConfig.DindImage,
			},
			client,
		)

		time.Sleep(5 * time.Second)
	}
}
