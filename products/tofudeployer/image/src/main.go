package main

import (
	"os"

	"github.com/go-git/go-git/v6"
	"github.com/go-git/go-git/v6/plumbing"
	"wieman.cloud/tofudeployer/tofu"
)

func main() {
	dryRun := true
	repo := "https://github.com/wiemanboy/WieCloud.git"
	branch := "create-tofudeployer"
	cloneTarget := "output"
	path := "products/tofudeployer/image/tofu"

	// stage files
	_, err := git.PlainClone(cloneTarget, &git.CloneOptions{
		URL:           repo,
		ReferenceName: plumbing.NewBranchReferenceName(branch),
		Depth:         1,
		SingleBranch:  true,
	})

	if err != nil {
		panic(err)
	}

	err = os.Chdir(cloneTarget + "/" + path)

	if err != nil {
		panic(err)
	}

	// tofu init
	_, err = tofu.Init()

	if err != nil {
		panic(err)
	}

	// tofu plan -> exit on fail or dry run
	_, err = tofu.Plan()

	if err != nil {
		panic(err)
	}

	if dryRun {
		return
	}

	// tofu apply
	_, err = tofu.Apply()

	if err != nil {
		panic(err)
	}
}
