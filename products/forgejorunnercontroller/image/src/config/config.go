package config

import (
	"os"
	"strconv"
)

type Config struct {
	ControllerName   string
	DesiredRunners   int
	RunnerSecretName string
	RunnerNamespace  string
	RunnerImage      string
	DindImage        string
	ForgejoNamespace string
	ForgejoImage     string
	KubectlImage     string
}

func LoadConfig() *Config {
	return &Config{
		ControllerName:   os.Getenv("CONTROLLER_NAME"),
		DesiredRunners:   toInt(os.Getenv("DESIRED_RUNNERS")),
		RunnerSecretName: os.Getenv("RUNNER_SECRET_NAME"),
		RunnerNamespace:  os.Getenv("RUNNER_NAMESPACE"),
		RunnerImage:      os.Getenv("RUNNER_IMAGE"),
		DindImage:        os.Getenv("DIND_IMAGE"),
		ForgejoNamespace: os.Getenv("FORGEJO_NAMESPACE"),
		ForgejoImage:     os.Getenv("FORGEJO_IMAGE"),
		KubectlImage:     os.Getenv("KUBECTL_IMAGE"),
	}
}

func toInt(string string) int {
	integer, _ := strconv.Atoi(string)
	return integer
}
