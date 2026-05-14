package main

import (
	"github.com/go-git/go-git/v6"
	"github.com/go-git/go-git/v6/plumbing"
	"wieman.cloud/tofudeployer/tofu"
)

func main() {
	dryRun := true
	repo := "https://github.com/wiemanboy/WieCloud.git"
	branch := "master"
	// path := "products/tofudeployer/image/tofu"

	// stage files
	git.PlainClone("output", &git.CloneOptions{
		URL:           repo,
		ReferenceName: plumbing.NewBranchReferenceName(branch),
		Depth:         1,
		SingleBranch:  true,
	})

	// tofu init
	tofu.Init()

	// tofu plan -> exit on fail or dry run
	tofu.Plan()

	if dryRun {
		return
	}

	// tofu apply
	tofu.Apply()
}
