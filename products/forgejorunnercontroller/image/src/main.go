package main

import (
	"log"
	"time"

	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
	"wieman.cloud/forgejorunnercontroller/config"
	"wieman.cloud/forgejorunnercontroller/runner"
	"wieman.cloud/forgejorunnercontroller/runner/configmap"
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
		log.Println("Get config checksum")
		configChecksum, err := configmap.GetChecksum(appConfig.RunnerConfigName, appConfig.RunnerNamespace, client)

		if err != nil {
			log.Println("Error getting config checksum")
			log.Fatal(err)
		}

		runnerSpec := runner.Runner{
			Name:           "wiecloud-runner",
			Label:          "wieman.cloud/forgejo-runner",
			Instance:       "https://forgejo.wieman.cloud",
			Namespace:      appConfig.RunnerNamespace,
			Image:          appConfig.RunnerImage,
			DindImage:      appConfig.DindImage,
			ConfigChecksum: configChecksum,
		}

		log.Println("Update deploy checksum annotation")
		runner.UpdateChecksums(runnerSpec, client)

		log.Println("Create ", appConfig.DesiredRunners, " runners")
		err = runner.Create(
			appConfig.DesiredRunners,
			appConfig.RunnerSecretName,
			runner.Register{
				Namespace:    appConfig.ForgejoNamespace,
				ForgejoImage: appConfig.ForgejoImage,
				KubectlImage: appConfig.KubectlImage,
			},
			runnerSpec,
			client,
		)

		if err != nil {
			log.Println("Error creating runners")
			log.Fatal(err)
		}

		time.Sleep(5 * time.Second)
	}
}
