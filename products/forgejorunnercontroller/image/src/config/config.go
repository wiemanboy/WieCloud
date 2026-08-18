package config

import (
	"os"
	"strconv"
)

type Config struct {
	DesiredRunners   int
	RunnerSecretName string
	RunnerNamespace  string
	ForgejoNamespace string
}

func LoadConfig() *Config {
	return &Config{
		DesiredRunners:   toInt(os.Getenv("DESIRED_RUNNERS")),
		RunnerSecretName: os.Getenv("RUNNER_SECRET_NAME"),
		RunnerNamespace:  os.Getenv("RUNNER_NAMESPACE"),
		ForgejoNamespace: os.Getenv("FORGEJO_NAMESPACE"),
	}
}

func toInt(string string) int {
	integer, _ := strconv.Atoi(string)
	return integer
}
