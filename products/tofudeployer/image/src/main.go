package main

import (
	"wieman.cloud/tofudeployer/tofu"
)

func main() {
	// stage files
	// stage variables
	dryRun := true

	// tofu init
	tofu.Init();

	// tofu plan -> exit on fail or dry run
	tofu.Plan();

	if dryRun {
		return
	}

	// tofu apply
	tofu.Apply();
}
